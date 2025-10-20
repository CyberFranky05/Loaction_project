<script lang="ts">
	import { authStore } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	onMount(() => {
		// Redirect to dashboard if already logged in
		if ($authStore.isAuthenticated) {
			goto('/dashboard');
		}
	});
</script>

<div class="container">
	<div class="hero">
		<h1>Welcome to Location Auth System</h1>
		<p class="subtitle">
			Secure authentication with location tracking and comprehensive sign-in monitoring
		</p>

		<div class="features">
			<div class="feature">
				<div class="icon">🔐</div>
				<h3>Secure Authentication</h3>
				<p>Powered by Keycloak with strong password policies</p>
			</div>
			<div class="feature">
				<div class="icon">🌍</div>
				<h3>Location Tracking</h3>
				<p>Automatic IP geolocation for every sign-in</p>
			</div>
			<div class="feature">
				<div class="icon">📊</div>
				<h3>Sign-in Monitoring</h3>
				<p>Track all authentication attempts with detailed logs</p>
			</div>
		</div>

		<div class="actions">
			<a href="/signup" class="btn btn-primary">Get Started</a>
			<a href="/signin" class="btn btn-secondary">Sign In</a>
		</div>
	</div>
</div>

<style>
	.container {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem;
		min-height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.hero {
		text-align: center;
	}

	h1 {
		font-size: 3rem;
		margin-bottom: 1rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	.subtitle {
		font-size: 1.25rem;
		color: #6c757d;
		margin-bottom: 3rem;
		max-width: 600px;
		margin-left: auto;
		margin-right: auto;
	}

	.features {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 2rem;
		margin: 3rem 0;
	}

	.feature {
		padding: 2rem;
		background: white;
		border-radius: 12px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		transition: transform 0.2s ease, box-shadow 0.2s ease;
	}

	.feature:hover {
		transform: translateY(-4px);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
	}

	.icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.feature h3 {
		margin: 0.5rem 0;
		color: #343a40;
		font-size: 1.25rem;
	}

	.feature p {
		color: #6c757d;
		margin: 0;
	}

	.actions {
		display: flex;
		gap: 1rem;
		justify-content: center;
		margin-top: 3rem;
	}

	.btn {
		padding: 1rem 2rem;
		font-size: 1.1rem;
		border-radius: 8px;
		text-decoration: none;
		font-weight: 600;
		transition: all 0.2s ease;
		display: inline-block;
	}

	.btn-primary {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.btn-primary:hover {
		transform: translateY(-2px);
		box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
	}

	.btn-secondary {
		background: white;
		color: #667eea;
		border: 2px solid #667eea;
	}

	.btn-secondary:hover {
		background: #667eea;
		color: white;
	}

	@media (max-width: 768px) {
		h1 {
			font-size: 2rem;
		}

		.subtitle {
			font-size: 1rem;
		}

		.features {
			grid-template-columns: 1fr;
		}

		.actions {
			flex-direction: column;
		}

		.btn {
			width: 100%;
		}
	}
</style>
