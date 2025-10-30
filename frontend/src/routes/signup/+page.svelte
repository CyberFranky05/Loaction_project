<script lang="ts">
	import { authAPI, type SignUpData } from '$lib/services/api';
	import PasswordStrength from '$lib/components/PasswordStrength.svelte';
	import { isPasswordValid } from '$lib/utils/password';
	import { getClientPublicIP } from '$lib/utils/ip';
	import { goto } from '$app/navigation';

	let name = '';
	let email = '';
	let password = '';
	let confirmPassword = '';
	let loading = false;
	let error = '';
	let success = false;

	$: passwordsMatch = password === confirmPassword && confirmPassword.length > 0;
	$: isValid = name && email && password && passwordsMatch && isPasswordValid(password);

	async function handleSubmit() {
		console.log('handleSubmit called');
		error = '';
		
		if (!isValid) {
			console.log('Form is not valid');
			error = 'Please fill in all fields correctly';
			return;
		}

		if (!passwordsMatch) {
			console.log('Passwords do not match');
			error = 'Passwords do not match';
			return;
		}

		loading = true;
		console.log('Submitting signup with:', { name, email });

		try {
			// Fetch client's public IP for accurate geolocation
			const clientIp = await getClientPublicIP();
			
			const data: SignUpData = { 
				name, 
				email, 
				password,
				...(clientIp && { clientIp })
			};
			console.log('Calling authAPI.signUp...');
			const response = await authAPI.signUp(data);
			console.log('Signup response:', response);
			
			success = true;
			
			// Wait a moment for Keycloak to finish creating the user
			await new Promise(resolve => setTimeout(resolve, 1000));
			
			// Automatically sign in the user after successful registration
			try {
				console.log('Auto-signing in user...');
				await authAPI.signIn({ email, password });
				console.log('Auto sign-in successful, redirecting to dashboard...');
				
				// Redirect to dashboard
				goto('/dashboard');
			} catch (loginErr: any) {
				console.error('Auto-login failed:', loginErr);
				// If auto-login fails, redirect to signin page
				setTimeout(() => {
					goto('/signin');
				}, 2000);
			}
		} catch (err: any) {
			console.error('Signup error:', err);
			console.error('Error response:', err.response);
			console.error('Error data:', err.response?.data);
			console.error('Error message from server:', err.response?.data?.message);
			error = err.response?.data?.message || err.message || 'Failed to sign up';
		} finally {
			loading = false;
		}
	}
</script>

<div class="container">
	<div class="form-wrapper">
		<div class="header">
			<h1>Create Account</h1>
			<p>Join us to start tracking your sign-in attempts</p>
		</div>

		{#if success}
			<div class="alert alert-success">
				✓ Account created successfully! Signing you in...
			</div>
		{/if}

		{#if error}
			<div class="alert alert-error">
				{error}
			</div>
		{/if}

		<form on:submit|preventDefault={handleSubmit}>
			<div class="form-group">
				<label for="name">Full Name</label>
				<input
					id="name"
					type="text"
					bind:value={name}
					placeholder="John Doe"
					required
					disabled={loading || success}
				/>
			</div>

			<div class="form-group">
				<label for="email">Email Address</label>
				<input
					id="email"
					type="email"
					bind:value={email}
					placeholder="john@example.com"
					required
					disabled={loading || success}
				/>
			</div>

			<div class="form-group">
				<label for="password">Password</label>
				<input
					id="password"
					type="password"
					bind:value={password}
					placeholder="••••••••"
					required
					disabled={loading || success}
				/>
			</div>

			{#if password}
				<PasswordStrength {password} />
			{/if}

			<div class="form-group">
				<label for="confirmPassword">Confirm Password</label>
				<input
					id="confirmPassword"
					type="password"
					bind:value={confirmPassword}
					placeholder="••••••••"
					required
					disabled={loading || success}
					class:error={confirmPassword && !passwordsMatch}
					class:success={passwordsMatch}
				/>
				{#if confirmPassword && !passwordsMatch}
					<span class="field-error">Passwords do not match</span>
				{/if}
				{#if passwordsMatch}
					<span class="field-success">✓ Passwords match</span>
				{/if}
			</div>

			<button type="submit" class="btn btn-primary" disabled={!isValid || loading || success}>
				{#if loading}
					Creating Account...
				{:else}
					Sign Up
				{/if}
			</button>
		</form>

		<div class="footer">
			Already have an account? <a href="/signin">Sign In</a>
		</div>
	</div>
</div>

<style>
	.container {
		max-width: 500px;
		margin: 2rem auto;
		padding: 2rem;
		min-height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.form-wrapper {
		width: 100%;
		background: white;
		padding: 2.5rem;
		border-radius: 12px;
		box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
	}

	.header {
		text-align: center;
		margin-bottom: 2rem;
	}

	h1 {
		margin: 0 0 0.5rem 0;
		color: #343a40;
		font-size: 2rem;
	}

	.header p {
		color: #6c757d;
		margin: 0;
	}

	.alert {
		padding: 1rem;
		border-radius: 8px;
		margin-bottom: 1.5rem;
		font-weight: 500;
	}

	.alert-success {
		background: #d4edda;
		color: #155724;
		border: 1px solid #c3e6cb;
	}

	.alert-error {
		background: #f8d7da;
		color: #721c24;
		border: 1px solid #f5c6cb;
	}

	.form-group {
		margin-bottom: 1.5rem;
	}

	label {
		display: block;
		margin-bottom: 0.5rem;
		color: #495057;
		font-weight: 600;
		font-size: 0.9rem;
	}

	input {
		width: 100%;
		padding: 0.75rem 1rem;
		font-size: 1rem;
		border: 2px solid #e9ecef;
		border-radius: 8px;
		transition: all 0.2s ease;
		box-sizing: border-box;
	}

	input:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	input:disabled {
		background: #f8f9fa;
		cursor: not-allowed;
	}

	input.error {
		border-color: #dc3545;
	}

	input.success {
		border-color: #28a745;
	}

	.field-error {
		display: block;
		margin-top: 0.25rem;
		color: #dc3545;
		font-size: 0.875rem;
	}

	.field-success {
		display: block;
		margin-top: 0.25rem;
		color: #28a745;
		font-size: 0.875rem;
		font-weight: 500;
	}

	.btn {
		width: 100%;
		padding: 1rem;
		font-size: 1.1rem;
		font-weight: 600;
		border: none;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.2s ease;
		margin-top: 1rem;
	}

	.btn-primary {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
	}

	.btn-primary:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
	}

	.btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
		transform: none;
	}

	.footer {
		text-align: center;
		margin-top: 1.5rem;
		color: #6c757d;
	}

	.footer a {
		color: #667eea;
		text-decoration: none;
		font-weight: 600;
	}

	.footer a:hover {
		text-decoration: underline;
	}

	@media (max-width: 576px) {
		.container {
			padding: 1rem;
		}

		.form-wrapper {
			padding: 1.5rem;
		}

		h1 {
			font-size: 1.5rem;
		}
	}
</style>
