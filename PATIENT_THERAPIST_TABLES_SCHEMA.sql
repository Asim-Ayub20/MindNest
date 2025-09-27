-- ============================================================================
-- MindNest Patient and Therapist Profile Tables - Minimal Implementation
-- ============================================================================
-- This extends the existing COMPLETE_CLEAN_DATABASE_SCHEMA.sql
-- Run this AFTER the main schema has been applied
-- Contains ONLY the fields currently implemented in the Flutter app
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Patients Table (Current Implementation Only)
-- ============================================================================

CREATE TABLE public.patients (
    -- Primary key (references the user's auth.users id)
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- Personal Information (from PatientDetailsScreen)
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    full_name TEXT NOT NULL,
    dob DATE NOT NULL, -- Date of birth
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    phone TEXT,
    
    -- Location Information
    country TEXT,
    city TEXT,
    location TEXT, -- Combined "country, city" format
    
    -- Language Preference
    preferred_lang TEXT DEFAULT 'English' CHECK (preferred_lang IN ('English', 'Urdu', 'Roman Urdu')),
    
    -- Emergency Contact Information
    emergency_first_name TEXT,
    emergency_last_name TEXT,
    emergency_name TEXT, -- Combined emergency contact name
    emergency_phone TEXT,
    
    -- Profile Picture
    profile_pic_url TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: Create Therapists Table (Current Implementation Only)
-- ============================================================================

CREATE TABLE public.therapists (
    -- Primary key (references the user's auth.users id)
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- Personal Information (from TherapistDetailsScreen)
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    full_name TEXT NOT NULL,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    phone TEXT,
    
    -- Location Information
    country TEXT,
    city TEXT,
    location TEXT, -- Combined "country, city" format
    
    -- Professional Information
    specialization TEXT[] DEFAULT '{}', -- Array of specializations
    qualifications TEXT NOT NULL,
    license_id TEXT NOT NULL,
    experience_years INTEGER DEFAULT 0 CHECK (experience_years >= 0),
    bio TEXT,
    
    -- Practice Information
    consultation_fee INTEGER DEFAULT 0 CHECK (consultation_fee >= 0),
    availability JSONB DEFAULT '{}'::jsonb, -- Schedule and availability data
    
    -- Profile Picture
    profile_pic_url TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 3: Create Storage Buckets for Profile Pictures
-- ============================================================================

-- Create storage bucket for patient profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'patient-profiles',
    'patient-profiles',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for therapist profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'therapist-profiles',
    'therapist-profiles',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 4: Create Basic Indexes for Performance
-- ============================================================================

-- Patients table indexes (basic ones only)
CREATE INDEX idx_patients_id ON public.patients(id);
CREATE INDEX idx_patients_full_name ON public.patients(full_name);
CREATE INDEX idx_patients_created_at ON public.patients(created_at);

-- Therapists table indexes (basic ones only)
CREATE INDEX idx_therapists_id ON public.therapists(id);
CREATE INDEX idx_therapists_full_name ON public.therapists(full_name);
CREATE INDEX idx_therapists_specialization ON public.therapists USING GIN(specialization);
CREATE INDEX idx_therapists_created_at ON public.therapists(created_at);

-- ============================================================================
-- STEP 5: Add Updated Timestamp Triggers
-- ============================================================================

-- Add automatic timestamp update triggers
CREATE TRIGGER update_patients_updated_at 
    BEFORE UPDATE ON public.patients 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_therapists_updated_at 
    BEFORE UPDATE ON public.therapists 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- STEP 6: Row Level Security (RLS) Policies - Basic Implementation
-- ============================================================================

-- Enable RLS on both tables
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapists ENABLE ROW LEVEL SECURITY;

-- Patients table policies - users can only manage their own data
CREATE POLICY "Users can view own patient profile" ON public.patients
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own patient profile" ON public.patients
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own patient profile" ON public.patients
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete own patient profile" ON public.patients
    FOR DELETE USING (auth.uid() = id);

-- Therapists table policies - users can only manage their own data
CREATE POLICY "Users can view own therapist profile" ON public.therapists
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own therapist profile" ON public.therapists
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own therapist profile" ON public.therapists
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete own therapist profile" ON public.therapists
    FOR DELETE USING (auth.uid() = id);

-- ============================================================================
-- STEP 7: Storage Policies for Profile Pictures
-- ============================================================================

-- Patient profile pictures policies
CREATE POLICY "Users can upload own patient profile picture" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'patient-profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view patient profile pictures" ON storage.objects
    FOR SELECT USING (bucket_id = 'patient-profiles');

CREATE POLICY "Users can update own patient profile picture" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'patient-profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own patient profile picture" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'patient-profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Therapist profile pictures policies
CREATE POLICY "Users can upload own therapist profile picture" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'therapist-profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view therapist profile pictures" ON storage.objects
    FOR SELECT USING (bucket_id = 'therapist-profiles');

CREATE POLICY "Users can update own therapist profile picture" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'therapist-profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own therapist profile picture" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'therapist-profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- STEP 8: Basic Helper Functions (Current Implementation Only)
-- ============================================================================

-- Simple function to get patient profile (only implemented fields)
CREATE OR REPLACE FUNCTION public.get_patient_profile(patient_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'id', p.id,
        'first_name', p.first_name,
        'last_name', p.last_name,
        'full_name', p.full_name,
        'dob', p.dob,
        'gender', p.gender,
        'phone', p.phone,
        'country', p.country,
        'city', p.city,
        'location', p.location,
        'preferred_lang', p.preferred_lang,
        'emergency_first_name', p.emergency_first_name,
        'emergency_last_name', p.emergency_last_name,
        'emergency_name', p.emergency_name,
        'emergency_phone', p.emergency_phone,
        'profile_pic_url', p.profile_pic_url,
        'created_at', p.created_at,
        'updated_at', p.updated_at
    ) INTO result
    FROM public.patients p
    WHERE p.id = patient_uuid;
    
    RETURN COALESCE(result, json_build_object('error', 'Patient not found'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Simple function to get therapist profile (only implemented fields)
CREATE OR REPLACE FUNCTION public.get_therapist_profile(therapist_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'id', t.id,
        'first_name', t.first_name,
        'last_name', t.last_name,
        'full_name', t.full_name,
        'gender', t.gender,
        'phone', t.phone,
        'country', t.country,
        'city', t.city,
        'location', t.location,
        'specialization', t.specialization,
        'qualifications', t.qualifications,
        'license_id', t.license_id,
        'experience_years', t.experience_years,
        'bio', t.bio,
        'consultation_fee', t.consultation_fee,
        'availability', t.availability,
        'profile_pic_url', t.profile_pic_url,
        'created_at', t.created_at,
        'updated_at', t.updated_at
    ) INTO result
    FROM public.therapists t
    WHERE t.id = therapist_uuid;
    
    RETURN COALESCE(result, json_build_object('error', 'Therapist not found'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 9: Grant Permissions
-- ============================================================================

-- Grant permissions on new tables
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patients TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.therapists TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.get_patient_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_therapist_profile(UUID) TO authenticated;

