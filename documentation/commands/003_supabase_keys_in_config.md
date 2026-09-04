# 003 — Add Supabase project keys to AppConfig

Date: 2026-09-04

## User command

Put these Supabase values into the app config:

- URL: `https://pkvvjicqbvbieltrgdov.supabase.co`
- anon/publishable key: `sb_publishable_ytLPhQYHLhYgRveAGdjxEQ_MR4-dnOu`

## What changed

- Updated `lib/config/app_config.dart` with the project URL and publishable key
- Android Studio Play continues to initialize Supabase from that file

## Note

Only the public anon/publishable key belongs in Flutter. Do not add a service-role key.
