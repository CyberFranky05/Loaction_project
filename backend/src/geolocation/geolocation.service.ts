import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface GeolocationData {
  ip: string;
  country?: string;
  city?: string;
  region?: string;
  latitude?: number;
  longitude?: number;
  timezone?: string;
  isp?: string;
}

@Injectable()
export class GeolocationService {
  private readonly apiUrl: string;

  constructor(private configService: ConfigService) {
    this.apiUrl = this.configService.get<string>('IPAPI_URL') || 'https://ipapi.co';
  }

  async getLocationFromIP(ipAddress: string): Promise<GeolocationData> {
    try {
      // Skip geolocation for localhost/private IPs
      if (this.isPrivateIP(ipAddress)) {
        return {
          ip: ipAddress,
          country: 'Local',
          city: 'Localhost',
          region: 'Development',
        };
      }

      const response = await axios.get(`${this.apiUrl}/${ipAddress}/json/`, {
        timeout: 5000,
      });

      const data = response.data;

      return {
        ip: ipAddress,
        country: data.country_name || data.country,
        city: data.city,
        region: data.region,
        latitude: data.latitude,
        longitude: data.longitude,
        timezone: data.timezone,
        isp: data.org || data.isp,
      };
    } catch (error) {
      console.error('Geolocation API error:', error.message);
      // Return basic info if API fails
      return {
        ip: ipAddress,
        country: 'Unknown',
        city: 'Unknown',
      };
    }
  }

  private isPrivateIP(ip: string): boolean {
    // Check for localhost
    if (ip === '::1' || ip === '127.0.0.1' || ip === 'localhost') {
      return true;
    }

    // Check for private IPv4 ranges
    const ipv4Regex = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    const match = ip.match(ipv4Regex);

    if (match) {
      const octets = match.slice(1).map(Number);
      // 10.0.0.0/8
      if (octets[0] === 10) return true;
      // 172.16.0.0/12
      if (octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31) return true;
      // 192.168.0.0/16
      if (octets[0] === 192 && octets[1] === 168) return true;
    }

    return false;
  }

  extractIPFromRequest(request: any): string {
    // Try various headers for the real IP
    const forwarded = request.headers['x-forwarded-for'];
    if (forwarded) {
      return forwarded.split(',')[0].trim();
    }

    return (
      request.headers['x-real-ip'] ||
      request.connection?.remoteAddress ||
      request.socket?.remoteAddress ||
      request.ip ||
      '127.0.0.1'
    );
  }

  parseUserAgent(userAgent: string): {
    browser?: string;
    device?: string;
    os?: string;
  } {
    if (!userAgent) {
      return {};
    }

    const result: any = {};

    // Detect Browser
    if (userAgent.includes('Firefox')) {
      result.browser = 'Firefox';
    } else if (userAgent.includes('Chrome')) {
      result.browser = 'Chrome';
    } else if (userAgent.includes('Safari') && !userAgent.includes('Chrome')) {
      result.browser = 'Safari';
    } else if (userAgent.includes('Edge')) {
      result.browser = 'Edge';
    } else if (userAgent.includes('Opera') || userAgent.includes('OPR')) {
      result.browser = 'Opera';
    }

    // Detect OS
    if (userAgent.includes('Windows')) {
      result.os = 'Windows';
    } else if (userAgent.includes('Mac OS')) {
      result.os = 'macOS';
    } else if (userAgent.includes('Linux')) {
      result.os = 'Linux';
    } else if (userAgent.includes('Android')) {
      result.os = 'Android';
    } else if (userAgent.includes('iOS') || userAgent.includes('iPhone') || userAgent.includes('iPad')) {
      result.os = 'iOS';
    }

    // Detect Device
    if (userAgent.includes('Mobile')) {
      result.device = 'Mobile';
    } else if (userAgent.includes('Tablet') || userAgent.includes('iPad')) {
      result.device = 'Tablet';
    } else {
      result.device = 'Desktop';
    }

    return result;
  }
}
