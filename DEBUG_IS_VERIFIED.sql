-- ============================================================================
-- Debug is_verified issue - Check actual database state
-- ============================================================================
-- Run this to see what's actually in your therapists table
-- ============================================================================

-- Check the structure and current values
SELECT 
    id,
    full_name,
    is_verified,
    created_at,
    updated_at
FROM public.therapists
ORDER BY created_at DESC;

-- Check if there are any NULL values in is_verified
SELECT 
    id,
    full_name,
    is_verified,
    CASE 
        WHEN is_verified IS NULL THEN 'NULL'
        WHEN is_verified = true THEN 'TRUE' 
        WHEN is_verified = false THEN 'FALSE'
        ELSE 'OTHER'
    END as verification_status
FROM public.therapists;
