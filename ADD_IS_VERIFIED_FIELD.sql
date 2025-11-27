-- ============================================================================
-- Add is_verified field to therapists table
-- ============================================================================
-- This script adds the is_verified field that was missing from the schema
-- Run this script in your Supabase SQL editor
-- ============================================================================

-- Add is_verified column to therapists table
ALTER TABLE public.therapists 
ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;

-- Create an index on is_verified for better query performance
CREATE INDEX idx_therapists_is_verified ON public.therapists(is_verified);

-- Update existing records to be unverified by default
UPDATE public.therapists SET is_verified = FALSE WHERE is_verified IS NULL;

-- Display confirmation
DO $$
BEGIN
    RAISE NOTICE 'Successfully added is_verified field to therapists table';
    RAISE NOTICE 'All existing therapist profiles are now marked as unverified (is_verified = false)';
    RAISE NOTICE 'Therapists will need to complete their profiles to be verified';
END $$;
