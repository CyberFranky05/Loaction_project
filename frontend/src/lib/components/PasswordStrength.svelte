<script lang="ts">
	import { validatePassword, type PasswordRequirement } from '$lib/utils/password';

	export let password: string = '';

	$: requirements = validatePassword(password);
</script>

<div class="password-requirements">
	<h4>Password Requirements:</h4>
	<ul>
		{#each requirements as req}
			<li class:met={req.met} class:not-met={!req.met}>
				<span class="icon">{req.met ? '✓' : '✗'}</span>
				<span class="label">{req.label}</span>
			</li>
		{/each}
	</ul>
</div>

<style>
	.password-requirements {
		margin-top: 1rem;
		padding: 1rem;
		background: #f8f9fa;
		border-radius: 8px;
		border: 1px solid #e9ecef;
	}

	h4 {
		margin: 0 0 0.75rem 0;
		font-size: 0.9rem;
		color: #495057;
		font-weight: 600;
	}

	ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	li {
		display: flex;
		align-items: center;
		padding: 0.4rem 0;
		font-size: 0.875rem;
		transition: all 0.2s ease;
	}

	.icon {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 20px;
		height: 20px;
		margin-right: 0.5rem;
		border-radius: 50%;
		font-weight: bold;
		font-size: 0.75rem;
	}

	.met .icon {
		background: #28a745;
		color: white;
	}

	.not-met .icon {
		background: #dc3545;
		color: white;
	}

	.met .label {
		color: #28a745;
		font-weight: 500;
	}

	.not-met .label {
		color: #6c757d;
	}
</style>
