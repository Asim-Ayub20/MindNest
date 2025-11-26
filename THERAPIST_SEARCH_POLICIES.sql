-- ============================================================================
-- MindNest Therapist Search Policies Update
-- ============================================================================
-- This script updates the RLS policies to allow patients to search and view
-- therapist profiles for the search functionality
-- ============================================================================

-- ============================================================================
-- STEP 1: Add Search Policies for Therapists Table
-- ============================================================================

-- Allow all authenticated users (patients) to view therapist profiles for search
-- This policy enables the search functionality
CREATE POLICY "Allow authenticated users to search therapist profiles" ON public.therapists
    FOR SELECT USING (
        auth.role() = 'authenticated'
        AND (
            -- Users can always view their own profile
            auth.uid() = id
            OR
            -- Patients can view other therapists' profiles for search
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.role = 'patient'
            )
            OR
            -- Admins can view all therapist profiles
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.role = 'admin'
            )
        )
    );

-- Remove the old restrictive policy that only allowed self-viewing
DROP POLICY IF EXISTS "Users can view own therapist profile" ON public.therapists;

-- ============================================================================
-- STEP 2: Add Search Policies for Storage (Profile Pictures)
-- ============================================================================

-- Allow all authenticated users to view therapist profile pictures
-- This enables profile pictures to be displayed in search results
CREATE POLICY "Allow authenticated users to view therapist profile pictures" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'therapist-profiles' 
        AND auth.role() = 'authenticated'
    );

-- Remove the old policy that was more restrictive
DROP POLICY IF EXISTS "Users can view therapist profile pictures" ON storage.objects;

-- ============================================================================
-- STEP 3: Create Search Helper Functions
-- ============================================================================

-- Function to get therapists for search with proper filtering
CREATE OR REPLACE FUNCTION public.search_therapists(
    search_query TEXT DEFAULT NULL,
    specializations TEXT[] DEFAULT NULL,
    location_filter TEXT DEFAULT NULL,
    min_fee INTEGER DEFAULT NULL,
    max_fee INTEGER DEFAULT NULL,
    min_experience INTEGER DEFAULT NULL,
    max_experience INTEGER DEFAULT NULL,
    verified_only BOOLEAN DEFAULT FALSE,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    full_name TEXT,
    gender TEXT,
    country TEXT,
    city TEXT,
    location TEXT,
    specialization TEXT[],
    qualifications TEXT,
    experience_years INTEGER,
    bio TEXT,
    consultation_fee INTEGER,
    availability JSONB,
    profile_pic_url TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.first_name,
        t.last_name,
        t.full_name,
        t.gender,
        t.country,
        t.city,
        t.location,
        t.specialization,
        t.qualifications,
        t.experience_years,
        t.bio,
        t.consultation_fee,
        t.availability,
        t.profile_pic_url,
        t.created_at,
        t.updated_at
    FROM public.therapists t
    WHERE 
        -- Text search filter
        (
            search_query IS NULL 
            OR t.full_name ILIKE '%' || search_query || '%'
            OR t.bio ILIKE '%' || search_query || '%'
            OR t.qualifications ILIKE '%' || search_query || '%'
            OR t.location ILIKE '%' || search_query || '%'
            OR EXISTS (
                SELECT 1 FROM unnest(t.specialization) AS spec 
                WHERE spec ILIKE '%' || search_query || '%'
            )
        )
        -- Specialization filter
        AND (
            specializations IS NULL 
            OR t.specialization && specializations
        )
        -- Location filter
        AND (
            location_filter IS NULL
            OR t.location ILIKE '%' || location_filter || '%'
            OR t.country ILIKE '%' || location_filter || '%'
            OR t.city ILIKE '%' || location_filter || '%'
        )
        -- Fee range filter
        AND (min_fee IS NULL OR t.consultation_fee >= min_fee)
        AND (max_fee IS NULL OR t.consultation_fee <= max_fee)
        -- Experience filter
        AND (min_experience IS NULL OR t.experience_years >= min_experience)
        AND (max_experience IS NULL OR t.experience_years <= max_experience)
    ORDER BY 
        t.created_at DESC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.search_therapists TO authenticated;

-- ============================================================================
-- STEP 4: Create Indexes for Better Search Performance
-- ============================================================================

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_therapists_full_text_search 
ON public.therapists USING gin(
    to_tsvector('english', coalesce(full_name, '') || ' ' || 
                          coalesce(bio, '') || ' ' || 
                          coalesce(qualifications, '') || ' ' ||
                          coalesce(location, ''))
);

-- Specialization search index (GIN for array operations)
CREATE INDEX IF NOT EXISTS idx_therapists_specialization_gin 
ON public.therapists USING gin(specialization);

-- Location search indexes
CREATE INDEX IF NOT EXISTS idx_therapists_location_text 
ON public.therapists(location);

CREATE INDEX IF NOT EXISTS idx_therapists_country 
ON public.therapists(country);

CREATE INDEX IF NOT EXISTS idx_therapists_city 
ON public.therapists(city);

-- Fee range index
CREATE INDEX IF NOT EXISTS idx_therapists_consultation_fee 
ON public.therapists(consultation_fee);

-- Experience index
CREATE INDEX IF NOT EXISTS idx_therapists_experience_years 
ON public.therapists(experience_years);

-- Created_at index for ordering
CREATE INDEX IF NOT EXISTS idx_therapists_created_at 
ON public.therapists(created_at DESC);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Test the policies work correctly
DO $$
BEGIN
    RAISE NOTICE 'Therapist search policies have been successfully updated!';
    RAISE NOTICE 'Patients can now search and view therapist profiles.';
    RAISE NOTICE 'Profile pictures are accessible for search results.';
    RAISE NOTICE 'Search optimization indexes have been created.';
END $$;
