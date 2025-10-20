import { writable } from 'svelte/store';
import { browser } from '$app/environment';

interface User {
	id: string;
	email: string;
	name: string;
}

interface AuthState {
	isAuthenticated: boolean;
	user: User | null;
	accessToken: string | null;
	refreshToken: string | null;
}

// Initialize from localStorage if in browser
function createAuthStore() {
	const initialState: AuthState = {
		isAuthenticated: false,
		user: null,
		accessToken: null,
		refreshToken: null
	};

	// Load from localStorage if available
	if (browser) {
		const stored = localStorage.getItem('auth');
		if (stored) {
			try {
				const parsed = JSON.parse(stored);
				Object.assign(initialState, parsed);
			} catch (e) {
				console.error('Failed to parse stored auth:', e);
			}
		}
	}

	const { subscribe, set, update } = writable<AuthState>(initialState);

	return {
		subscribe,
		login: (accessToken: string, refreshToken: string, user: User) => {
			const newState: AuthState = {
				isAuthenticated: true,
				user,
				accessToken,
				refreshToken
			};
			set(newState);
			if (browser) {
				localStorage.setItem('auth', JSON.stringify(newState));
			}
		},
		logout: () => {
			const emptyState: AuthState = {
				isAuthenticated: false,
				user: null,
				accessToken: null,
				refreshToken: null
			};
			set(emptyState);
			if (browser) {
				localStorage.removeItem('auth');
			}
		},
		updateTokens: (accessToken: string, refreshToken: string) => {
			update((state) => {
				const newState = { ...state, accessToken, refreshToken };
				if (browser) {
					localStorage.setItem('auth', JSON.stringify(newState));
				}
				return newState;
			});
		}
	};
}

export const authStore = createAuthStore();
