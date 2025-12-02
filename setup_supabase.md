# Supabase Setup Guide

## 1. Create a Supabase Project
1. Go to [Supabase Dashboard](https://supabase.com/dashboard).
2. Click "New Project".
3. Enter a name (e.g., "AI Image Enhancer") and database password.
4. Select a region close to your users.

## 2. Database Schema

Run the following SQL in the **SQL Editor** to create the necessary tables.

```sql
-- Create a table for user profiles
create table profiles (
  id uuid references auth.users not null primary key,
  updated_at timestamp with time zone,
  username text unique,
  full_name text,
  avatar_url text,
  website text,
  is_pro boolean default false,
  stripe_customer_id text,
  
  constraint username_length check (char_length(username) >= 3)
);

-- Set up Row Level Security (RLS)
alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Create a table for tracking usage
create table usage_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  created_at timestamp with time zone default now(),
  feature_type text not null, -- 'unblur', 'upscale', 'colorize'
  input_image_path text,
  output_image_path text
);

-- RLS for usage_logs
alter table usage_logs enable row level security;

create policy "Users can view their own usage logs."
  on usage_logs for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own usage logs."
  on usage_logs for insert
  with check ( auth.uid() = user_id );
```

## 3. Storage Setup

1. Go to **Storage** in the dashboard.
2. Create a new bucket named `images`.
3. Set the bucket to **Public** (or keep private and use signed URLs, but public is easier for this demo).
4. Add RLS policies if not public:
    - Allow authenticated users to upload: `auth.role() = 'authenticated'`
    - Allow authenticated users to read: `auth.role() = 'authenticated'`

## 4. Edge Functions

You will need to deploy an Edge Function named `process_image`.

1. Install Supabase CLI: `npm install -g supabase`
2. Login: `supabase login`
3. Initialize: `supabase init`
4. Create function: `supabase functions new process_image`
5. Deploy: `supabase functions deploy process_image`

(See `supabase/functions/process_image/index.ts` in the codebase for the function logic).

## 5. Authentication

1. Go to **Authentication** -> **Providers**.
2. Enable **Google**.
3. You will need to configure the **Client ID** and **Secret** from Google Cloud Console.
    - [Supabase Google Auth Docs](https://supabase.com/docs/guides/auth/social-login/auth-google)
