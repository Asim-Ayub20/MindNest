-- ============================================================================
-- Check if is_verified column exists in therapists table
-- ============================================================================
-- Run this query to verify if the is_verified column has been added
-- ============================================================================

-- Check table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'therapists' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if any therapist records have is_verified data
SELECT id, full_name, is_verified, created_at
FROM public.therapists
LIMIT 5;
