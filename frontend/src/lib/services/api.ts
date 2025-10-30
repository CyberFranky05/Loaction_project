import axios from 'axios';
import { authStore } from '$lib/stores/auth';
import { get } from 'svelte/store';

// Use production URL - ENV vars don't work reliably in Docker builds
const API_URL = process.env.NODE_ENV === 'production' 
	? 'https://mrelectron.xyz/api/v1'
	: import.meta.env.PUBLIC_API_URL || 'http://localhost:3001/api/v1';

// Create axios instance
const api = axios.create({
	baseURL: API_URL,
	headers: {
		'Content-Type': 'application/json'
	}
});

// Add auth token to requests
api.interceptors.request.use((config) => {
	const auth = get(authStore);
	if (auth.accessToken) {
		config.headers.Authorization = `Bearer ${auth.accessToken}`;
	}
	return config;
});

// Handle token refresh on 401
api.interceptors.response.use(
	(response) => response,
	async (error) => {
		const originalRequest = error.config;

		if (error.response?.status === 401 && !originalRequest._retry) {
			originalRequest._retry = true;

			const auth = get(authStore);
			if (auth.refreshToken) {
				try {
					const response = await axios.post(`${API_URL}/auth/refresh`, {
						refresh_token: auth.refreshToken
					});

					const { access_token, refresh_token } = response.data;
					authStore.updateTokens(access_token, refresh_token);

					originalRequest.headers.Authorization = `Bearer ${access_token}`;
					return api(originalRequest);
				} catch (refreshError) {
					authStore.logout();
					window.location.href = '/signin';
					return Promise.reject(refreshError);
				}
			}
		}

		return Promise.reject(error);
	}
);

export interface SignUpData {
	name: string;
	email: string;
	password: string;
	clientIp?: string;
}

export interface SignInData {
	email: string;
	password: string;
	clientIp?: string;
}

export interface SignInAttempt {
	id: string;
	user_id: string;
	email: string;
	ip_address: string;
	country?: string;
	city?: string;
	region?: string;
	latitude?: number;
	longitude?: number;
	timezone?: string;
	isp?: string;
	user_agent?: string;
	browser?: string;
	device?: string;
	os?: string;
	success: boolean;
	failure_reason?: string;
	timestamp: string;
}

export const authAPI = {
	async signUp(data: SignUpData) {
		const response = await api.post('/auth/signup', data);
		return response.data;
	},

	async signIn(data: SignInData) {
		const response = await api.post('/auth/signin', data);
		const { access_token, refresh_token, user } = response.data;
		authStore.login(access_token, refresh_token, user);
		return response.data;
	},

	async logout() {
		const auth = get(authStore);
		if (auth.refreshToken) {
			try {
				await api.post('/auth/logout', { refresh_token: auth.refreshToken });
			} catch (e) {
				// Ignore logout errors
			}
		}
		authStore.logout();
	},

	async getProfile() {
		const response = await api.get('/auth/profile');
		return response.data;
	},

	async getSignInAttempts(limit = 50, offset = 0): Promise<{ attempts: SignInAttempt[]; total: number }> {
		const response = await api.get(`/auth/signin-attempts?limit=${limit}&offset=${offset}`);
		return response.data;
	}
};

export default api;
