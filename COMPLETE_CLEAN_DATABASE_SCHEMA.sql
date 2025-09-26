-- ============================================================================
-- MindNest Complete Clean Database Schema
-- ============================================================================
-- This is a COMPLETE REPLACEMENT for all previous database schemas
-- Removes OTP functionality and focuses on core authentication
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: CLEAN SLATE - Remove all existing tables and functions
-- ============================================================================

-- Drop all existing triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_email_verification ON auth.users;

-- Drop all functions
DROP FUNCTION IF EXISTS public.handle_new_auth_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_email_verification() CASCADE;
DROP FUNCTION IF EXISTS public.check_existing_user(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.check_existing_user(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.app_auth_check(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.enforce_email_verification(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.request_password_reset(TEXT, INET, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.log_user_login(UUID, BOOLEAN, TEXT, INET, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_info(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.create_user_account(TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.update_onboarding_progress(UUID, TEXT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_profile(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.log_otp_attempt(UUID, TEXT, TEXT, BOOLEAN, INET, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.log_password_reset(UUID, TEXT, TEXT, BOOLEAN, INET, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- Drop all views
DROP VIEW IF EXISTS public.user_profiles_with_onboarding CASCADE;
DROP VIEW IF EXISTS public.secure_user_lookup CASCADE;

-- Drop all tables (in correct order to handle foreign keys)
DROP TABLE IF EXISTS public.otp_login_attempts CASCADE;
DROP TABLE IF EXISTS public.otp_login_logs CASCADE;
DROP TABLE IF EXISTS public.password_resets CASCADE;
DROP TABLE IF EXISTS public.auth_logs CASCADE;
DROP TABLE IF EXISTS public.user_onboarding CASCADE;
DROP TABLE IF EXISTS public.email_verifications CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop all custom types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS account_status CASCADE;
DROP TYPE IF EXISTS onboarding_step CASCADE;
DROP TYPE IF EXISTS auth_action CASCADE;

-- ============================================================================
-- STEP 2: Create Core Tables with Simple Structure
-- ============================================================================

-- Main profiles table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    -- Primary identifiers
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    
    -- User type and status (using simple TEXT instead of enums)
    role TEXT NOT NULL DEFAULT 'patient' CHECK (role IN ('patient', 'therapist', 'admin')),
    status TEXT DEFAULT 'pending_verification' CHECK (status IN ('active', 'inactive', 'suspended', 'pending_verification')),
    
    -- Email verification
    is_email_confirmed BOOLEAN DEFAULT FALSE,
    email_confirmed_at TIMESTAMPTZ,
    
    -- Additional user info
    phone_number TEXT,
    date_of_birth DATE,
    timezone TEXT DEFAULT 'UTC',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    
    -- Soft delete support
    deleted_at TIMESTAMPTZ,
    
    -- Additional metadata (JSON for flexibility)
    metadata JSONB DEFAULT '{}'::jsonb
);

-- User onboarding progress tracking
CREATE TABLE public.user_onboarding (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Onboarding type based on user role
    onboarding_type TEXT NOT NULL CHECK (onboarding_type IN ('patient', 'therapist', 'admin')),
    
    -- Current step tracking (using simple TEXT)
    current_step TEXT DEFAULT 'user_type_selected' CHECK (current_step IN ('user_type_selected', 'account_created', 'onboarding_1', 'onboarding_2', 'onboarding_3', 'onboarding_4', 'completed')),
    
    -- Step completion tracking
    user_type_selected BOOLEAN DEFAULT FALSE,
    account_created BOOLEAN DEFAULT FALSE,
    onboarding_1_completed BOOLEAN DEFAULT FALSE,
    onboarding_2_completed BOOLEAN DEFAULT FALSE,
    onboarding_3_completed BOOLEAN DEFAULT FALSE,
    onboarding_4_completed BOOLEAN DEFAULT FALSE,
    
    -- Progress calculation
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    
    -- Completion tracking
    completed_at TIMESTAMPTZ,
    
    -- Onboarding data (store answers, preferences, etc.)
    onboarding_data JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Authentication logs (Security & Analytics) - NO OTP FIELDS
CREATE TABLE public.auth_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    
    -- Action details (using simple TEXT)
    action TEXT NOT NULL CHECK (action IN ('signup', 'login', 'logout', 'password_reset_request', 'password_reset_complete', 'email_verify')),
    success BOOLEAN NOT NULL DEFAULT FALSE,
    error_message TEXT,
    
    -- Security information
    ip_address INET,
    user_agent TEXT,
    device_info JSONB DEFAULT '{}'::jsonb,
    
    -- Location info (if available)
    country TEXT,
    city TEXT,
    
    -- Additional context
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Password reset management (NO OTP)
CREATE TABLE public.password_resets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    
    -- Reset token management (Supabase handles this, but we track requests)
    reset_requested_at TIMESTAMPTZ DEFAULT NOW(),
    reset_completed_at TIMESTAMPTZ,
    
    -- Security tracking
    ip_address INET,
    user_agent TEXT,
    
    -- Status
    success BOOLEAN DEFAULT FALSE,
    attempts_count INTEGER DEFAULT 1,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 3: Create Indexes for Performance
-- ============================================================================

-- Profiles indexes
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_status ON public.profiles(status);
CREATE INDEX idx_profiles_created_at ON public.profiles(created_at);
CREATE INDEX idx_profiles_last_login ON public.profiles(last_login_at);
CREATE INDEX idx_profiles_email_role ON public.profiles(email, role);

-- Onboarding indexes
CREATE INDEX idx_onboarding_user_id ON public.user_onboarding(user_id);
CREATE INDEX idx_onboarding_type ON public.user_onboarding(onboarding_type);
CREATE INDEX idx_onboarding_step ON public.user_onboarding(current_step);
CREATE INDEX idx_onboarding_progress ON public.user_onboarding(progress_percentage);

-- Auth logs indexes
CREATE INDEX idx_auth_logs_user_id ON public.auth_logs(user_id);
CREATE INDEX idx_auth_logs_action ON public.auth_logs(action);
CREATE INDEX idx_auth_logs_created_at ON public.auth_logs(created_at);
CREATE INDEX idx_auth_logs_success ON public.auth_logs(success);

-- Password reset indexes
CREATE INDEX idx_password_resets_email ON public.password_resets(email);
CREATE INDEX idx_password_resets_created_at ON public.password_resets(created_at);

-- ============================================================================
-- STEP 4: Create Updated Timestamp Function
-- ============================================================================

-- Function to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.profiles 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_onboarding_updated_at 
    BEFORE UPDATE ON public.user_onboarding 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- STEP 5: Core Authentication Functions
-- ============================================================================

-- Enhanced User Creation Function (NO OTP)
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_role_value TEXT;
    initial_status TEXT;
    user_full_name TEXT;
BEGIN
    -- Extract role from metadata, default to 'patient'
    user_role_value := COALESCE(NEW.raw_user_meta_data ->> 'role', 'patient');
    user_full_name := COALESCE(NEW.raw_user_meta_data ->> 'full_name', split_part(NEW.email, '@', 1));
    
    -- Set initial status based on email confirmation
    initial_status := CASE 
        WHEN NEW.email_confirmed_at IS NOT NULL THEN 'active'
        ELSE 'pending_verification'
    END;
    
    -- Create profile
    INSERT INTO public.profiles (
        id, 
        email, 
        full_name, 
        role, 
        status,
        is_email_confirmed,
        email_confirmed_at,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        user_full_name,
        user_role_value,
        initial_status,
        (NEW.email_confirmed_at IS NOT NULL),
        NEW.email_confirmed_at,
        NOW(),
        NOW()
    ) ON CONFLICT (email) DO UPDATE SET
        -- Update existing profile if it's the same user
        id = CASE WHEN profiles.id IS NULL THEN EXCLUDED.id ELSE profiles.id END,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        status = EXCLUDED.status,
        is_email_confirmed = EXCLUDED.is_email_confirmed,
        email_confirmed_at = EXCLUDED.email_confirmed_at,
        updated_at = NOW();
    
    -- Create onboarding progress record
    INSERT INTO public.user_onboarding (
        user_id, 
        onboarding_type,
        user_type_selected,
        account_created,
        current_step,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        user_role_value,
        TRUE,
        TRUE,
        'account_created',
        NOW(),
        NOW()
    ) ON CONFLICT (user_id) DO UPDATE SET
        onboarding_type = EXCLUDED.onboarding_type,
        user_type_selected = TRUE,
        account_created = TRUE,
        updated_at = NOW();
    
    -- Log the signup
    INSERT INTO public.auth_logs (
        user_id, 
        action, 
        success, 
        metadata,
        created_at
    ) VALUES (
        NEW.id, 
        'signup', 
        TRUE,
        json_build_object(
            'email', NEW.email, 
            'role', user_role_value,
            'email_confirmed', NEW.email_confirmed_at IS NOT NULL
        ),
        NOW()
    );
    
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the user creation
    INSERT INTO public.auth_logs (
        user_id, 
        action, 
        success, 
        error_message, 
        metadata,
        created_at
    ) VALUES (
        NEW.id, 
        'signup', 
        FALSE, 
        SQLERRM, 
        json_build_object('email', NEW.email, 'error', SQLERRM),
        NOW()
    );
    
    RETURN NEW;
END;
$$;

-- Email verification handler
CREATE OR REPLACE FUNCTION public.handle_email_verification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update profile when email gets verified
    IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
        UPDATE public.profiles SET
            is_email_confirmed = TRUE,
            email_confirmed_at = NEW.email_confirmed_at,
            status = 'active',
            updated_at = NOW()
        WHERE id = NEW.id;
        
        -- Log email verification
        INSERT INTO public.auth_logs (
            user_id,
            action,
            success,
            metadata,
            created_at
        ) VALUES (
            NEW.id,
            'email_verify',
            TRUE,
            json_build_object('email', NEW.email, 'verified_at', NEW.email_confirmed_at),
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- ============================================================================
-- STEP 6: Helper Functions
-- ============================================================================

-- Authentication check function (NO OTP)
CREATE OR REPLACE FUNCTION public.app_auth_check(
    user_email TEXT,
    check_type TEXT DEFAULT 'login'
)
RETURNS JSON AS $$
DECLARE
    user_info RECORD;
    result JSON;
BEGIN
    -- Get user information
    SELECT id, email, role, is_email_confirmed, status
    INTO user_info
    FROM public.profiles
    WHERE email = user_email AND deleted_at IS NULL;
    
    CASE check_type
        WHEN 'login' THEN
            IF user_info.id IS NULL THEN
                result := json_build_object(
                    'allowed', FALSE,
                    'reason', 'User not found'
                );
            ELSIF NOT user_info.is_email_confirmed THEN
                result := json_build_object(
                    'allowed', FALSE,
                    'reason', 'Email not verified',
                    'role', user_info.role
                );
            ELSIF user_info.status != 'active' THEN
                result := json_build_object(
                    'allowed', FALSE,
                    'reason', 'Account not active',
                    'status', user_info.status
                );
            ELSE
                result := json_build_object(
                    'allowed', TRUE,
                    'role', user_info.role,
                    'status', user_info.status
                );
            END IF;
            
        WHEN 'signup' THEN
            IF user_info.id IS NOT NULL THEN
                result := json_build_object(
                    'allowed', FALSE,
                    'reason', 'User already exists',
                    'existing_role', user_info.role,
                    'is_verified', user_info.is_email_confirmed
                );
            ELSE
                result := json_build_object('allowed', TRUE);
            END IF;
            
        WHEN 'password_reset' THEN
            IF user_info.id IS NULL THEN
                result := json_build_object(
                    'allowed', FALSE,
                    'reason', 'User not found'
                );
            ELSIF NOT user_info.is_email_confirmed THEN
                result := json_build_object(
                    'allowed', FALSE,
                    'reason', 'Email not verified'
                );
            ELSE
                result := json_build_object(
                    'allowed', TRUE,
                    'user_id', user_info.id
                );
            END IF;
            
        ELSE
            result := json_build_object(
                'allowed', FALSE,
                'reason', 'Invalid check type'
            );
    END CASE;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User login logging
CREATE OR REPLACE FUNCTION public.log_user_login(
    user_uuid UUID,
    login_success BOOLEAN,
    error_msg TEXT DEFAULT NULL,
    ip_addr INET DEFAULT NULL,
    user_agent_string TEXT DEFAULT NULL,
    device_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
BEGIN
    -- Update last login time if successful
    IF login_success THEN
        UPDATE public.profiles 
        SET last_login_at = NOW(), updated_at = NOW()
        WHERE id = user_uuid;
    END IF;
    
    -- Log the login attempt
    INSERT INTO public.auth_logs (
        user_id, 
        action, 
        success,
        error_message,
        ip_address,
        user_agent,
        device_info,
        created_at
    ) VALUES (
        user_uuid, 
        'login',
        login_success,
        error_msg,
        ip_addr,
        user_agent_string,
        device_metadata,
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Password reset logging (NO OTP)
CREATE OR REPLACE FUNCTION public.log_password_reset(
    user_uuid UUID,
    user_email TEXT,
    reset_type TEXT, -- 'request' or 'complete'
    success_status BOOLEAN,
    ip_addr INET DEFAULT NULL,
    user_agent_string TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Log the password reset action
    INSERT INTO public.auth_logs (
        user_id, 
        action,
        success,
        ip_address,
        user_agent,
        metadata,
        created_at
    ) VALUES (
        user_uuid, 
        CASE WHEN reset_type = 'request' THEN 'password_reset_request' ELSE 'password_reset_complete' END,
        success_status,
        ip_addr,
        user_agent_string,
        json_build_object('email', user_email, 'reset_type', reset_type),
        NOW()
    );
    
    -- Update password reset tracking
    IF reset_type = 'request' THEN
        INSERT INTO public.password_resets (
            user_id, 
            email, 
            ip_address, 
            user_agent,
            created_at
        ) VALUES (
            user_uuid, 
            user_email, 
            ip_addr, 
            user_agent_string,
            NOW()
        );
    ELSIF reset_type = 'complete' AND success_status THEN
        UPDATE public.password_resets 
        SET reset_completed_at = NOW(), success = TRUE
        WHERE id = (
            SELECT id FROM public.password_resets 
            WHERE user_id = user_uuid 
            AND reset_completed_at IS NULL
            ORDER BY created_at DESC 
            LIMIT 1
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get complete user profile
CREATE OR REPLACE FUNCTION public.get_user_profile(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'id', p.id,
        'email', p.email,
        'full_name', p.full_name,
        'avatar_url', p.avatar_url,
        'role', p.role,
        'status', p.status,
        'is_email_confirmed', p.is_email_confirmed,
        'email_confirmed_at', p.email_confirmed_at,
        'phone_number', p.phone_number,
        'date_of_birth', p.date_of_birth,
        'timezone', p.timezone,
        'created_at', p.created_at,
        'updated_at', p.updated_at,
        'last_login_at', p.last_login_at,
        'metadata', p.metadata,
        'onboarding', json_build_object(
            'type', uo.onboarding_type,
            'current_step', uo.current_step,
            'progress_percentage', uo.progress_percentage,
            'user_type_selected', uo.user_type_selected,
            'account_created', uo.account_created,
            'onboarding_1_completed', uo.onboarding_1_completed,
            'onboarding_2_completed', uo.onboarding_2_completed,
            'onboarding_3_completed', uo.onboarding_3_completed,
            'onboarding_4_completed', uo.onboarding_4_completed,
            'completed_at', uo.completed_at,
            'onboarding_data', uo.onboarding_data
        )
    ) INTO result
    FROM public.profiles p
    LEFT JOIN public.user_onboarding uo ON p.id = uo.user_id
    WHERE p.id = user_uuid AND p.deleted_at IS NULL;
    
    RETURN COALESCE(result, json_build_object('error', 'User not found'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update onboarding progress
CREATE OR REPLACE FUNCTION public.update_onboarding_progress(
    user_uuid UUID,
    step_name TEXT,
    completed BOOLEAN DEFAULT TRUE,
    step_data JSONB DEFAULT '{}'::jsonb
)
RETURNS JSON AS $$
DECLARE
    current_progress INTEGER;
    completed_count INTEGER;
    total_steps INTEGER := 6; -- user_type_selected, account_created, onboarding_1-4
BEGIN
    -- Update the specific step
    CASE step_name
        WHEN 'user_type_selected' THEN
            UPDATE public.user_onboarding 
            SET user_type_selected = completed, updated_at = NOW()
            WHERE user_id = user_uuid;
        WHEN 'account_created' THEN
            UPDATE public.user_onboarding 
            SET account_created = completed, updated_at = NOW()
            WHERE user_id = user_uuid;
        WHEN 'onboarding_1' THEN
            UPDATE public.user_onboarding 
            SET onboarding_1_completed = completed, updated_at = NOW()
            WHERE user_id = user_uuid;
        WHEN 'onboarding_2' THEN
            UPDATE public.user_onboarding 
            SET onboarding_2_completed = completed, updated_at = NOW()
            WHERE user_id = user_uuid;
        WHEN 'onboarding_3' THEN
            UPDATE public.user_onboarding 
            SET onboarding_3_completed = completed, updated_at = NOW()
            WHERE user_id = user_uuid;
        WHEN 'onboarding_4' THEN
            UPDATE public.user_onboarding 
            SET onboarding_4_completed = completed, updated_at = NOW()
            WHERE user_id = user_uuid;
    END CASE;
    
    -- Calculate progress percentage
    SELECT (
        CASE WHEN user_type_selected THEN 1 ELSE 0 END +
        CASE WHEN account_created THEN 1 ELSE 0 END +
        CASE WHEN onboarding_1_completed THEN 1 ELSE 0 END +
        CASE WHEN onboarding_2_completed THEN 1 ELSE 0 END +
        CASE WHEN onboarding_3_completed THEN 1 ELSE 0 END +
        CASE WHEN onboarding_4_completed THEN 1 ELSE 0 END
    ) INTO completed_count
    FROM public.user_onboarding 
    WHERE user_id = user_uuid;
    
    current_progress := (completed_count * 100) / total_steps;
    
    -- Update progress and completion status
    UPDATE public.user_onboarding 
    SET 
        progress_percentage = current_progress,
        current_step = CASE 
            WHEN current_progress = 100 THEN 'completed'
            ELSE step_name
        END,
        completed_at = CASE 
            WHEN current_progress = 100 THEN NOW()
            ELSE completed_at
        END,
        onboarding_data = onboarding_data || step_data,
        updated_at = NOW()
    WHERE user_id = user_uuid;
    
    -- If onboarding is complete, update profile status
    IF current_progress = 100 THEN
        UPDATE public.profiles 
        SET status = 'active', updated_at = NOW()
        WHERE id = user_uuid;
    END IF;
    
    RETURN json_build_object(
        'success', TRUE, 
        'progress_percentage', current_progress,
        'completed', current_progress = 100
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 7: Create Triggers
-- ============================================================================

-- Create the main trigger for new users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Create the email verification trigger
CREATE TRIGGER on_email_verification
    AFTER UPDATE OF email_confirmed_at ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_email_verification();

-- ============================================================================
-- STEP 8: Row Level Security (RLS) Setup
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_onboarding ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_resets ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Onboarding policies
CREATE POLICY "Users can view own onboarding" ON public.user_onboarding
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own onboarding" ON public.user_onboarding
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own onboarding" ON public.user_onboarding
    FOR UPDATE USING (auth.uid() = user_id);

-- Auth logs policies (users can view their own logs)
CREATE POLICY "Users can view own auth logs" ON public.auth_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Password reset policies
CREATE POLICY "Users can view own password resets" ON public.password_resets
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 9: Grant Permissions
-- ============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_onboarding TO authenticated;
GRANT SELECT, INSERT ON public.auth_logs TO authenticated;
GRANT SELECT, INSERT ON public.password_resets TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.app_auth_check(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_user_login(UUID, BOOLEAN, TEXT, INET, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_password_reset(UUID, TEXT, TEXT, BOOLEAN, INET, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_onboarding_progress(UUID, TEXT, BOOLEAN, JSONB) TO authenticated;

-- ============================================================================
-- STEP 10: Verification and Testing
-- ============================================================================

-- Test the auth check function
SELECT 'Testing auth functions...' as test_status;
SELECT public.app_auth_check('test@example.com', 'signup') as signup_test;
SELECT public.app_auth_check('test@example.com', 'login') as login_test;

-- Verify tables were created
SELECT 'Tables created:' as status, COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'user_onboarding', 'auth_logs', 'password_resets');

-- Verify functions were created
SELECT 'Functions created:' as status, COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('app_auth_check', 'log_user_login', 'get_user_profile', 'update_onboarding_progress');

-- Verify triggers were created
SELECT 'Triggers created:' as status, COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE trigger_name IN ('on_auth_user_created', 'on_email_verification');

-- Final verification
SELECT 'Database schema setup completed successfully! 🎉' as final_status;

-- ============================================================================
-- SETUP COMPLETE! 
-- ============================================================================
-- This schema provides:
-- ✅ Clean authentication without OTP
-- ✅ Proper email verification enforcement
-- ✅ Role-based access (patient/therapist/admin)
-- ✅ Onboarding progress tracking
-- ✅ Comprehensive audit logging
-- ✅ Password reset functionality
-- ✅ Duplicate account prevention
-- ✅ Proper RLS security
-- ============================================================================
