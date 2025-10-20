<script lang="ts">
	import { authAPI, type SignInData } from '$lib/services/api';
	import { authStore } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let email = '';
	let password = '';
	let loading = false;
	let error = '';

	$: isValid = email && password;

	onMount(() => {
		// Redirect to dashboard if already authenticated
		if ($authStore.isAuthenticated) {
			goto('/dashboard');
		}
	});

	async function handleSubmit() {
		error = '';
		
		if (!isValid) {
			error = 'Please enter your email and password';
			return;
		}

		loading = true;

		try {
			const data: SignInData = { email, password };
			await authAPI.signIn(data); // authAPI.signIn already handles login
			goto('/dashboard');
		} catch (err: any) {
			const message = err.response?.data?.message || err.message;
			if (message?.includes('Invalid credentials')) {
				error = 'Invalid email or password. Please try again.';
			} else {
				error = message || 'Failed to sign in';
			}
		} finally {
			loading = false;
		}
	}
</script>

<div class="container">
	<div class="form-wrapper">
		<div class="header">
			<h1>Welcome Back</h1>
			<p>Sign in to view your secure dashboard</p>
		</div>

		{#if error}
			<div class="alert alert-error">
				{error}
			</div>
		{/if}

		<form on:submit|preventDefault={handleSubmit}>
			<div class="form-group">
				<label for="email">Email Address</label>
				<input
					id="email"
					type="email"
					bind:value={email}
					placeholder="john@example.com"
					required
					disabled={loading}
					autocomplete="email"
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
					disabled={loading}
					autocomplete="current-password"
				/>
			</div>

			<button type="submit" class="btn btn-primary" disabled={!isValid || loading}>
				{#if loading}
					Signing In...
				{:else}
					Sign In
				{/if}
			</button>
		</form>

		<div class="footer">
			Don't have an account? <a href="/signup">Sign Up</a>
		</div>
	</div>
</div>

<style>
	.container {
		max-width: 450px;
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
