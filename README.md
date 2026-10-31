# Blessing Osagie GOLDEN FRAME AI

Commercial starter for a two-workflow AI photography service. **Identity Fusion is the flagship workflow**; Composition Recreation is the second workflow.

## Included
- Next.js customer-facing branded studio
- Two master prompts (composition and identity fusion)
- Facial identity, hairstyle, clothing and grading controls
- Supabase authentication foundation and PostgreSQL schema
- Server-side image-generation route with credit debit/refund RPC calls
- Paystack transaction initialization and signed webhook verification
- Private storage bucket setup and generation history schema

## Important launch status
This is a deployment-ready starter, not a live service. No cloud accounts, domain, API credentials, SMS provider, production email configuration, or hosting project are included. Do not accept customer payments until the production checklist below is completed and tested.

## Deploy
1. Create a Supabase project. Run `supabase/schema.sql` in its SQL editor.
2. Configure Supabase Auth email confirmation and phone OTP. Configure a supported SMS provider in Supabase Auth. Verify phone ownership before granting the trial bonus.
3. Create a Vercel project and import this repository.
4. Set every variable in `.env.example` in Vercel project settings. Keep service-role and provider secrets server-only.
5. Set `APP_BASE_URL` to the production domain. Configure Paystack webhook URL as `https://YOUR_DOMAIN/api/paystack/webhook`.
6. Configure allowed redirect URLs in Supabase Auth.
7. Deploy and test in staging before production.

## Required production work before public launch
- Add a secure onboarding endpoint / database trigger that creates a profile only after verified email AND verified phone, and grants the five free credits exactly once. The unique ledger reference must be `signup:<auth-user-id>`.
- Enforce unique normalized phone numbers and email addresses in a trusted server workflow; add database unique indexes after normalizing existing data.
- Add abuse controls: hashed IP rate-limit records, CAPTCHA, velocity detection and administrator review. Avoid hard one-person-per-IP blocking because carrier-grade NAT and shared networks create false positives.
- Configure Supabase storage policies and use signed URLs for private generated images. Do not expose customer images publicly.
- Add user-scoped history and transaction read policies, admin roles/MFA, audit logs, data retention and deletion workflow.
- Verify Paystack webhook signature and transaction amount/currency/reference against the pending database row. Add reconciliation and refund handling.
- Add image upload validation, malware/content checks, size limits, rate limits, queueing, timeouts and robust job status tracking.
- Review OpenAI image API's current image-edit input requirements and model availability. The starter sends both references to the image edit endpoint; a production identity-fusion pipeline may require a dedicated multi-reference model or face-preserving compositing workflow. Never promise mathematically identical facial pixels from generative output.
- Add legal pages: Terms, Privacy, refund policy, image consent and acceptable-use policy.
- Add monitoring, backups, alerts, load tests and security review.

## Image generation
The API key is only used server-side. Never expose `OPENAI_API_KEY` or `SUPABASE_SERVICE_ROLE_KEY` in client code. The current API route uses a one-credit atomic debit and attempts a refund if the generation request fails. Validate the exact image model and input schema against the provider's current documentation before production.

## Packages (NGN)
- Free trial: 5 credits (one time)
- Starter: ₦1,000 / 10 credits
- Creator: ₦3,000 / 40 credits
- Professional: ₦5,000 / 80 credits

## Local development
```bash
cp .env.example .env.local
npm install
npm run dev
```
