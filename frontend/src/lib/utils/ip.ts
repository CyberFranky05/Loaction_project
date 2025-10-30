/**
 * Utility to fetch the client's public IP address
 * Uses ipify.org API as a reliable free service
 */

export async function getClientPublicIP(): Promise<string | null> {
	try {
		console.log('🌐 Fetching client public IP...');
		const response = await fetch('https://api.ipify.org?format=json', {
			method: 'GET',
			headers: {
				'Accept': 'application/json',
			},
			// Short timeout to avoid blocking the UI
			signal: AbortSignal.timeout(3000),
		});

		if (!response.ok) {
			console.warn('⚠️ Failed to fetch public IP:', response.status);
			return null;
		}

		const data = await response.json();
		console.log('✅ Client public IP fetched:', data.ip);
		return data.ip;
	} catch (error) {
		console.error('❌ Error fetching client public IP:', error);
		return null;
	}
}
