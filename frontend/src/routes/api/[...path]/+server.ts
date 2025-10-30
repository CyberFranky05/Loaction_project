/**
 * Vercel Serverless API Proxy
 * Forwards all /api/* requests to the EC2 backend
 * This solves HTTPS mixed content issues (Vercel HTTPS -> EC2 HTTP)
 */

import type { RequestHandler } from './$types';

// EC2 backend IP
const BACKEND_URL = 'http://13.232.210.108';

export const GET: RequestHandler = async ({ request, params }) => {
	return proxyRequest(request, params.path, 'GET');
};

export const POST: RequestHandler = async ({ request, params }) => {
	return proxyRequest(request, params.path, 'POST');
};

export const PUT: RequestHandler = async ({ request, params }) => {
	return proxyRequest(request, params.path, 'PUT');
};

export const DELETE: RequestHandler = async ({ request, params }) => {
	return proxyRequest(request, params.path, 'DELETE');
};

export const PATCH: RequestHandler = async ({ request, params }) => {
	return proxyRequest(request, params.path, 'PATCH');
};

async function proxyRequest(request: Request, path: string, method: string): Promise<Response> {
	try {
		// Build full path - path already includes /api prefix from route
		const fullPath = `/api/${path}`;
		const url = `${BACKEND_URL}${fullPath}`;

		console.log(`[Proxy] ${method} ${fullPath} -> ${url}`);

		// Get request body if present
		let body: string | undefined;
		if (method !== 'GET' && method !== 'DELETE') {
			try {
				body = await request.text();
			} catch (e) {
				body = undefined;
			}
		}

		// Forward headers (preserve Authorization, Content-Type, etc.)
		const headers = new Headers();
		request.headers.forEach((value, key) => {
			// Skip host header
			if (key.toLowerCase() !== 'host') {
				headers.set(key, value);
			}
		});

		// Make request to backend
		const backendResponse = await fetch(url, {
			method,
			headers,
			body,
		});

		// Get response body
		const responseBody = await backendResponse.arrayBuffer();

		// Create response with backend status and headers
		const responseHeaders = new Headers(backendResponse.headers);
		
		// Add CORS headers for frontend
		responseHeaders.set('Access-Control-Allow-Origin', '*');
		responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
		responseHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

		return new Response(responseBody, {
			status: backendResponse.status,
			statusText: backendResponse.statusText,
			headers: responseHeaders,
		});
	} catch (error) {
		console.error('[Proxy] Error:', error);
		return new Response(
			JSON.stringify({ error: 'Proxy error', message: error instanceof Error ? error.message : 'Unknown error' }),
			{
				status: 500,
				headers: {
					'Content-Type': 'application/json',
					'Access-Control-Allow-Origin': '*',
				},
			}
		);
	}
}

// Handle OPTIONS preflight requests
export const OPTIONS: RequestHandler = async () => {
	return new Response(null, {
		status: 204,
		headers: {
			'Access-Control-Allow-Origin': '*',
			'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
			'Access-Control-Allow-Headers': 'Content-Type, Authorization',
			'Access-Control-Max-Age': '86400',
		},
	});
};
