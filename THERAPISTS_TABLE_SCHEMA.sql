-- ============================================================================
-- MindNest Therapists Table Schema Addition
-- ============================================================================
-- This script adds the therapists table and related functionality to the existing schema
-- Run this in Supabase SQL Editor if you already have the base schema
-- ============================================================================

-- Create the therapists table
CREATE TABLE IF NOT EXISTS public.therapists (
    -- Primary identifiers
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- Personal details
    full_name TEXT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    phone TEXT NOT NULL,
    location TEXT NOT NULL,
    
    -- Professional details
    specialization TEXT[] NOT NULL,
    qualifications TEXT NOT NULL,
    license_id TEXT NOT NULL,
    experience_years INTEGER NOT NULL CHECK (experience_years >= 0),
    bio TEXT NOT NULL,
    consultation_fee DECIMAL(10,2) NOT NULL CHECK (consultation_fee > 0),
    availability JSONB NOT NULL DEFAULT '{"schedule": "Weekdays (9 AM - 5 PM)"}',
    
    -- Profile picture
    profile_pic_url TEXT,
    
    -- Status and verification
    is_verified BOOLEAN DEFAULT FALSE,
    verification_date TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for the therapists table
CREATE INDEX IF NOT EXISTS idx_therapists_id ON public.therapists(id);
CREATE INDEX IF NOT EXISTS idx_therapists_phone ON public.therapists(phone);
CREATE INDEX IF NOT EXISTS idx_therapists_location ON public.therapists(location);
CREATE INDEX IF NOT EXISTS idx_therapists_specialization ON public.therapists USING GIN (specialization);
CREATE INDEX IF NOT EXISTS idx_therapists_experience ON public.therapists(experience_years);
CREATE INDEX IF NOT EXISTS idx_therapists_fee ON public.therapists(consultation_fee);
CREATE INDEX IF NOT EXISTS idx_therapists_verified ON public.therapists(is_verified);
CREATE INDEX IF NOT EXISTS idx_therapists_created_at ON public.therapists(created_at);

-- Add trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS update_therapists_updated_at ON public.therapists;
CREATE TRIGGER update_therapists_updated_at 
    BEFORE UPDATE ON public.therapists 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enable RLS on therapists table
ALTER TABLE public.therapists ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for therapists
DROP POLICY IF EXISTS "Therapists can view own details" ON public.therapists;
CREATE POLICY "Therapists can view own details" ON public.therapists
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Therapists can insert own details" ON public.therapists;
CREATE POLICY "Therapists can insert own details" ON public.therapists
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Therapists can update own details" ON public.therapists;
CREATE POLICY "Therapists can update own details" ON public.therapists
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Public can view verified therapists" ON public.therapists;
CREATE POLICY "Public can view verified therapists" ON public.therapists
    FOR SELECT USING (is_verified = true);

-- Grant permissions for therapists table
GRANT SELECT, INSERT, UPDATE ON public.therapists TO authenticated;

-- Create storage bucket for therapist profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('therapist-profiles', 'therapist-profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for therapist-profiles bucket
DROP POLICY IF EXISTS "Therapists can upload own profile picture" ON storage.objects;
CREATE POLICY "Therapists can upload own profile picture"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'therapist-profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can view therapist profile pictures" ON storage.objects;
CREATE POLICY "Users can view therapist profile pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'therapist-profiles');

DROP POLICY IF EXISTS "Therapists can update own profile picture" ON storage.objects;
CREATE POLICY "Therapists can update own profile picture"
ON storage.objects FOR UPDATE
USING (bucket_id = 'therapist-profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Verification
SELECT 'Therapists table setup completed successfully! 🎉' as status;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'therapists' AND table_schema = 'public')
        THEN 'Therapists table created ✅'
        ELSE 'Therapists table creation failed ❌'
    END as table_status;