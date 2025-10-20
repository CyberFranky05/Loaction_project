export interface PasswordRequirement {
	id: string;
	label: string;
	test: (password: string) => boolean;
	met: boolean;
}

export function validatePassword(password: string): PasswordRequirement[] {
	const requirements: PasswordRequirement[] = [
		{
			id: 'length',
			label: 'At least 8 characters',
			test: (pwd) => pwd.length >= 8,
			met: false
		},
		{
			id: 'uppercase',
			label: 'At least one uppercase letter (A-Z)',
			test: (pwd) => /[A-Z]/.test(pwd),
			met: false
		},
		{
			id: 'lowercase',
			label: 'At least one lowercase letter (a-z)',
			test: (pwd) => /[a-z]/.test(pwd),
			met: false
		},
		{
			id: 'number',
			label: 'At least one number (0-9)',
			test: (pwd) => /\d/.test(pwd),
			met: false
		},
		{
			id: 'special',
			label: 'At least one special character (@$!%*?&)',
			test: (pwd) => /[@$!%*?&]/.test(pwd),
			met: false
		}
	];

	return requirements.map((req) => ({
		...req,
		met: req.test(password)
	}));
}

export function isPasswordValid(password: string): boolean {
	const requirements = validatePassword(password);
	return requirements.every((req) => req.met);
}
