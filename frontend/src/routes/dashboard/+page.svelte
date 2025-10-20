<script lang="ts">
	import { authAPI } from '$lib/services/api';
	import { authStore } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	interface SignInAttempt {
		id: string;
		ip_address: string;
		country?: string;
		city?: string;
		region?: string;
		latitude?: number;
		longitude?: number;
		timezone?: string;
		isp?: string;
		browser?: string;
		device?: string;
		os?: string;
		success: boolean;
		timestamp: string;
	}

	let attempts: SignInAttempt[] = [];
	let loading = true;
	let error = '';

	onMount(async () => {
		// Redirect to signin if not authenticated
		if (!$authStore.isAuthenticated) {
			goto('/signin');
			return;
		}

		await fetchAttempts();
	});

	async function fetchAttempts() {
		loading = true;
		error = '';

		try {
			const response = await authAPI.getSignInAttempts();
			attempts = response.attempts;
		} catch (err: any) {
			error = err.response?.data?.message || err.message || 'Failed to load sign-in attempts';
		} finally {
			loading = false;
		}
	}

	async function handleLogout() {
		try {
			await authAPI.logout();
		} catch (err) {
			console.error('Logout error:', err);
		} finally {
			authStore.logout();
			goto('/signin');
		}
	}

	function formatDate(dateString: string): string {
		const date = new Date(dateString);
		return date.toLocaleString('en-US', {
			year: 'numeric',
			month: 'short',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function getLocation(attempt: SignInAttempt): string {
		const parts = [];
		if (attempt.city) parts.push(attempt.city);
		if (attempt.region) parts.push(attempt.region);
		if (attempt.country) parts.push(attempt.country);
		return parts.length > 0 ? parts.join(', ') : 'Unknown';
	}

	function getCoordinates(attempt: SignInAttempt): string {
		if (attempt.latitude && attempt.longitude) {
			return `${attempt.latitude.toFixed(4)}, ${attempt.longitude.toFixed(4)}`;
		}
		return 'N/A';
	}

	function getMapLink(attempt: SignInAttempt): string {
		if (attempt.latitude && attempt.longitude) {
			return `https://www.google.com/maps?q=${attempt.latitude},${attempt.longitude}`;
		}
		return '#';
	}
</script>

<div class="dashboard">
	<header class="header">
		<div class="header-content">
			<div class="header-left">
				<h1>Dashboard</h1>
				<p>Welcome back, {$authStore.user?.name || 'User'}!</p>
			</div>
			<div class="header-right">
				<button class="btn btn-outline" on:click={fetchAttempts} disabled={loading}>
					{#if loading}
						Refreshing...
					{:else}
						🔄 Refresh
					{/if}
				</button>
				<button class="btn btn-danger" on:click={handleLogout}>
					Logout
				</button>
			</div>
		</div>
	</header>

	<main class="main-content">
		<div class="card">
			<div class="card-header">
				<h2>Sign-In Attempts</h2>
				<span class="badge">{attempts.length} total</span>
			</div>

			{#if error}
				<div class="alert alert-error">
					{error}
				</div>
			{/if}

			{#if loading}
				<div class="loading">
					<div class="spinner"></div>
					<p>Loading sign-in attempts...</p>
				</div>
			{:else if attempts.length === 0}
				<div class="empty-state">
					<p>No sign-in attempts found</p>
				</div>
			{:else}
				<div class="table-container">
					<table class="attempts-table">
						<thead>
							<tr>
								<th>Status</th>
								<th>Date & Time</th>
								<th>IP Address</th>
								<th>Location</th>
								<th>Coordinates</th>
								<th>Timezone</th>
								<th>ISP</th>
								<th>Browser</th>
								<th>Device</th>
								<th>OS</th>
								<th>Map</th>
							</tr>
						</thead>
						<tbody>
							{#each attempts as attempt}
								<tr class:failed={!attempt.success}>
									<td>
										{#if attempt.success}
											<span class="status status-success">✓ Success</span>
										{:else}
											<span class="status status-failed">✗ Failed</span>
										{/if}
									</td>
									<td>{formatDate(attempt.timestamp)}</td>
									<td><code class="ip-code">{attempt.ip_address}</code></td>
									<td>
										<div class="location-cell">
											<span class="location-text">{getLocation(attempt)}</span>
										</div>
									</td>
									<td>
										<code class="coords-code">{getCoordinates(attempt)}</code>
									</td>
									<td>{attempt.timezone || 'N/A'}</td>
									<td class="isp-cell">{attempt.isp || 'Unknown'}</td>
									<td>{attempt.browser || 'Unknown'}</td>
									<td>{attempt.device || 'Unknown'}</td>
									<td>{attempt.os || 'Unknown'}</td>
									<td>
										{#if attempt.latitude && attempt.longitude}
											<a 
												href={getMapLink(attempt)} 
												target="_blank" 
												rel="noopener noreferrer"
												class="map-link"
												title="View on Google Maps"
											>
												🗺️ View
											</a>
										{:else}
											<span class="text-muted">N/A</span>
										{/if}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</div>
	</main>
</div>

<style>
	.dashboard {
		min-height: 100vh;
		background: #f8f9fa;
	}

	.header {
		background: white;
		border-bottom: 1px solid #e9ecef;
		padding: 1.5rem 0;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
	}

	.header-content {
		max-width: 1400px;
		margin: 0 auto;
		padding: 0 2rem;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.header-left h1 {
		margin: 0 0 0.25rem 0;
		color: #343a40;
		font-size: 1.75rem;
	}

	.header-left p {
		margin: 0;
		color: #6c757d;
	}

	.header-right {
		display: flex;
		gap: 1rem;
	}

	.main-content {
		max-width: 1400px;
		margin: 2rem auto;
		padding: 0 2rem;
	}

	.card {
		background: white;
		border-radius: 12px;
		box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
		overflow: hidden;
	}

	.card-header {
		padding: 1.5rem 2rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.card-header h2 {
		margin: 0;
		font-size: 1.5rem;
	}

	.badge {
		background: rgba(255, 255, 255, 0.2);
		padding: 0.5rem 1rem;
		border-radius: 20px;
		font-weight: 600;
		font-size: 0.9rem;
	}

	.alert {
		padding: 1rem 2rem;
		margin: 1.5rem 2rem;
		border-radius: 8px;
		font-weight: 500;
	}

	.alert-error {
		background: #f8d7da;
		color: #721c24;
		border: 1px solid #f5c6cb;
	}

	.loading {
		padding: 4rem 2rem;
		text-align: center;
		color: #6c757d;
	}

	.spinner {
		width: 40px;
		height: 40px;
		margin: 0 auto 1rem;
		border: 4px solid #e9ecef;
		border-top-color: #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.empty-state {
		padding: 4rem 2rem;
		text-align: center;
		color: #6c757d;
	}

	.table-container {
		overflow-x: auto;
	}

	.attempts-table {
		width: 100%;
		border-collapse: collapse;
	}

	.attempts-table thead {
		background: #f8f9fa;
	}

	.attempts-table th {
		padding: 1rem 1.5rem;
		text-align: left;
		font-weight: 600;
		color: #495057;
		font-size: 0.9rem;
		text-transform: uppercase;
		letter-spacing: 0.5px;
		border-bottom: 2px solid #e9ecef;
	}

	.attempts-table td {
		padding: 1rem 1.5rem;
		border-bottom: 1px solid #e9ecef;
		color: #495057;
		font-size: 0.9rem;
	}

	.ip-code {
		background: #f1f3f5;
		padding: 0.25rem 0.5rem;
		border-radius: 4px;
		font-family: 'Courier New', monospace;
		font-size: 0.875rem;
		color: #495057;
	}

	.coords-code {
		background: #e7f5ff;
		padding: 0.25rem 0.5rem;
		border-radius: 4px;
		font-family: 'Courier New', monospace;
		font-size: 0.875rem;
		color: #1971c2;
	}

	.location-cell {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.location-text {
		font-weight: 500;
	}

	.isp-cell {
		max-width: 200px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-size: 0.875rem;
		color: #868e96;
	}

	.map-link {
		display: inline-flex;
		align-items: center;
		gap: 0.25rem;
		padding: 0.375rem 0.75rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		text-decoration: none;
		border-radius: 6px;
		font-size: 0.875rem;
		font-weight: 600;
		transition: all 0.2s ease;
	}

	.map-link:hover {
		transform: translateY(-1px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
	}

	.text-muted {
		color: #adb5bd;
		font-size: 0.875rem;
	}

	.attempts-table tbody tr {
		transition: background 0.2s ease;
	}

	.attempts-table tbody tr:hover {
		background: #f8f9fa;
	}

	.attempts-table tbody tr.failed {
		background: #fff5f5;
	}

	.status {
		display: inline-block;
		padding: 0.375rem 0.75rem;
		border-radius: 6px;
		font-weight: 600;
		font-size: 0.875rem;
	}

	.status-success {
		background: #d4edda;
		color: #155724;
	}

	.status-failed {
		background: #f8d7da;
		color: #721c24;
	}

	code {
		background: #f8f9fa;
		padding: 0.25rem 0.5rem;
		border-radius: 4px;
		font-family: 'Courier New', monospace;
		font-size: 0.875rem;
		color: #667eea;
	}

	.btn {
		padding: 0.75rem 1.5rem;
		font-size: 1rem;
		font-weight: 600;
		border: none;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.btn-outline {
		background: white;
		color: #667eea;
		border: 2px solid #667eea;
	}

	.btn-outline:hover:not(:disabled) {
		background: #667eea;
		color: white;
	}

	.btn-danger {
		background: #dc3545;
		color: white;
	}

	.btn-danger:hover {
		background: #c82333;
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(220, 53, 69, 0.3);
	}

	.btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	@media (max-width: 1200px) {
		.attempts-table {
			font-size: 0.9rem;
		}

		.attempts-table th,
		.attempts-table td {
			padding: 0.75rem 1rem;
		}
	}

	@media (max-width: 768px) {
		.header-content {
			flex-direction: column;
			gap: 1rem;
			align-items: flex-start;
		}

		.header-right {
			width: 100%;
		}

		.header-right .btn {
			flex: 1;
		}

		.main-content {
			padding: 0 1rem;
		}

		.card-header {
			flex-direction: column;
			gap: 0.75rem;
			align-items: flex-start;
		}

		.attempts-table {
			font-size: 0.8rem;
		}

		.attempts-table th,
		.attempts-table td {
			padding: 0.5rem 0.75rem;
		}
	}
</style>
