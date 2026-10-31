create extension if not exists pgcrypto;
create table if not exists public.profiles(
 user_id uuid primary key references auth.users(id) on delete cascade,
 email text unique,
 phone text unique,
 phone_verified boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.credit_ledger(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 delta integer not null,
 reason text not null,
 reference text unique,
 created_at timestamptz not null default now()
);
create table if not exists public.payments(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 reference text not null unique,
 package_id text not null,
 amount_kobo integer not null,
 credits integer not null,
 status text not null default 'pending',
 created_at timestamptz not null default now()
);
create table if not exists public.generations(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 mode text not null check(mode in ('identity_fusion','composition')),
 prompt text not null,
 storage_path text,
 status text not null default 'completed',
 created_at timestamptz not null default now()
);
create table if not exists public.generation_jobs(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 ledger_reference text not null unique,
 created_at timestamptz not null default now()
);
create or replace function public.user_credit_balance(p_user_id uuid)
returns integer language sql security definer set search_path=public as $$
 select coalesce(sum(delta),0)::integer from public.credit_ledger where user_id=p_user_id;
$$;
create or replace function public.consume_generation_credit(p_user_id uuid,p_mode text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare j uuid; bal integer;
begin
 perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));
 bal:=public.user_credit_balance(p_user_id);
 if bal<1 then raise exception 'Insufficient credits'; end if;
 j:=gen_random_uuid();
 insert into generation_jobs(user_id,ledger_reference) values(p_user_id,j::text);
 insert into credit_ledger(user_id,delta,reason,reference) values(p_user_id,-1,'image_generation',j::text);
 return jsonb_build_object('job_id',j);
end $$;
create or replace function public.refund_generation_credit(p_user_id uuid,p_job_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
 insert into credit_ledger(user_id,delta,reason,reference)
 values(p_user_id,1,'generation_refund','refund:'||p_job_id::text)
 on conflict(reference) do nothing;
end $$;
create or replace function public.settle_paystack_payment(p_reference text)
returns void language plpgsql security definer set search_path=public as $$
declare p payments%rowtype;
begin
 select * into p from payments where reference=p_reference for update;
 if not found then raise exception 'Unknown payment reference'; end if;
 if p.status='success' then return; end if;
 update payments set status='success' where id=p.id;
 insert into credit_ledger(user_id,delta,reason,reference)
 values(p.user_id,p.credits,'paystack_purchase','payment:'||p.reference)
 on conflict(reference) do nothing;
end $$;
-- Secure defaults: no public reads/writes to financial tables. Add user-scoped RLS policies
-- for customer history after reviewing your production authentication and storage setup.
alter table profiles enable row level security;
alter table credit_ledger enable row level security;
alter table payments enable row level security;
alter table generations enable row level security;
alter table generation_jobs enable row level security;
create policy "profile owner reads profile" on profiles for select using(auth.uid()=user_id);
create policy "generation owner reads history" on generations for select using(auth.uid()=user_id);
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('generated-images','generated-images',false,12582912,array['image/png','image/jpeg','image/webp'])
on conflict(id) do nothing;

-- These privileged RPCs are called only after the API route validates the user's
-- bearer token, or by the verified Paystack webhook. Do not grant them to anon/authenticated.
revoke all on function public.consume_generation_credit(uuid,text) from public, anon, authenticated;
revoke all on function public.refund_generation_credit(uuid,uuid) from public, anon, authenticated;
revoke all on function public.settle_paystack_payment(text) from public, anon, authenticated;
grant execute on function public.consume_generation_credit(uuid,text) to service_role;
grant execute on function public.refund_generation_credit(uuid,uuid) to service_role;
grant execute on function public.settle_paystack_payment(text) to service_role;
