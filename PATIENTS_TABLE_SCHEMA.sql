-- ============================================================================
-- MindNest Patients Table Schema Addition
-- ============================================================================
-- This script adds the patients table and related functionality to the existing schema
-- Run this in Supabase SQL Editor if you already have the base schema
-- ============================================================================

-- Create the patients table
CREATE TABLE IF NOT EXISTS public.patients (
    -- Primary identifiers
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- Personal details
    full_name TEXT NOT NULL,
    dob DATE NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    phone TEXT NOT NULL,
    location TEXT NOT NULL,
    preferred_lang TEXT NOT NULL DEFAULT 'English' CHECK (preferred_lang IN ('English', 'Urdu', 'Roman Urdu')),
    
    -- Emergency contact
    emergency_name TEXT NOT NULL,
    emergency_phone TEXT NOT NULL,
    
    -- Profile picture
    profile_pic_url TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for the patients table
CREATE INDEX IF NOT EXISTS idx_patients_id ON public.patients(id);
CREATE INDEX IF NOT EXISTS idx_patients_phone ON public.patients(phone);
CREATE INDEX IF NOT EXISTS idx_patients_location ON public.patients(location);
CREATE INDEX IF NOT EXISTS idx_patients_gender ON public.patients(gender);
CREATE INDEX IF NOT EXISTS idx_patients_created_at ON public.patients(created_at);

-- Add trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS update_patients_updated_at ON public.patients;
CREATE TRIGGER update_patients_updated_at 
    BEFORE UPDATE ON public.patients 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enable RLS on patients table
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for patients
DROP POLICY IF EXISTS "Patients can view own details" ON public.patients;
CREATE POLICY "Patients can view own details" ON public.patients
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Patients can insert own details" ON public.patients;
CREATE POLICY "Patients can insert own details" ON public.patients
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Patients can update own details" ON public.patients;
CREATE POLICY "Patients can update own details" ON public.patients
    FOR UPDATE USING (auth.uid() = id);

-- Grant permissions for patients table
GRANT SELECT, INSERT, UPDATE ON public.patients TO authenticated;

-- Create storage bucket for patient profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('patient-profiles', 'patient-profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for patient-profiles bucket
DROP POLICY IF EXISTS "Users can upload own profile picture" ON storage.objects;
CREATE POLICY "Users can upload own profile picture"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'patient-profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can view profile pictures" ON storage.objects;
CREATE POLICY "Users can view profile pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'patient-profiles');

DROP POLICY IF EXISTS "Users can update own profile picture" ON storage.objects;
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
USING (bucket_id = 'patient-profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Verification
SELECT 'Patients table setup completed successfully! 🎉' as status;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'patients' AND table_schema = 'public')
        THEN 'Patients table created ✅'
        ELSE 'Patients table creation failed ❌'
    END as table_status;