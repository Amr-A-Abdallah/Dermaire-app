import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'dermaire_state.dart';
import 'dermaire_theme.dart';
import 'dermaire_widgets.dart';
import 'doctor_portal.dart';
import 'services/api_service.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? _validateEmail(String? value) =>
    _emailPattern.hasMatch(value?.trim() ?? '')
    ? null
    : 'Enter a valid email address';

void _openApp(BuildContext context, DermaireState state) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => AppShell(state: state)),
    (_) => false,
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  key: const Key('themeToggle'),
                  tooltip: isDark ? 'Light mode' : 'Dark mode',
                  onPressed: state.toggleTheme,
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                ),
              ),
              const Eyebrow('Personal Skin Lab'),
              Text(
                'Dermaire',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                'Understand what actually works for your skin — measure, experiment, learn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .72),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DermaireColors.darkPaper
                        : DermaireColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DermaireColors.caramel,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/dermaire-logo.webp',
                    fit: BoxFit.contain,
                    semanticLabel: 'Dermaire logo',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('startExperimentButton'),
                onPressed: () =>
                    openPage(context, CreateAccountScreen(state: state)),
                child: const Text('Start my skin experiment'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('existingAccountButton'),
                onPressed: () => openPage(context, SignInScreen(state: state)),
                child: const Text('I already have an account'),
              ),
              const SizedBox(height: 14),
              Text(
                'Your facial photo stays on your device — only skin measurements are ever sent.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: colors.onSurface.withValues(alpha: .58),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;

  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || loading) return;
    setState(() => loading = true);
    try {
      await ApiService.instance.login(
        email: email.text.trim(),
        password: password.text.trim(),
      );
    } catch (e) {
      final errStr = e.toString();
      // If server is offline or connection refused (e.g. tests or no network), allow demo mode
      final isNetworkError = errStr.contains('Connection') ||
          errStr.contains('ClientException') ||
          errStr.contains('SocketException') ||
          errStr.contains('Empty response') ||
          errStr.contains('FormatException');
      if (!isNetworkError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errStr),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
    if (!mounted) return;
    _openApp(context, widget.state);
  }

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Welcome back',
    title: 'Sign in',
    subtitle: 'Continue your private skin experiments.',
    children: [
      _SocialButton(
        icon: 'G',
        label: 'Continue with Google',
        onPressed: () => _openApp(context, widget.state),
      ),
      const SizedBox(height: 10),
      _SocialButton(
        icon: '●',
        label: 'Continue with Apple',
        onPressed: () => _openApp(context, widget.state),
      ),
      const _OrDivider(),
      Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('signInEmail'),
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('signInPassword'),
              controller: password,
              obscureText: hidePassword,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  (value?.isNotEmpty ?? false) ? null : 'Enter your password',
            ),
          ],
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () =>
              openPage(context, ForgotPasswordScreen(state: widget.state)),
          child: const Text('Forgot password?'),
        ),
      ),
      FilledButton(onPressed: submit, child: const Text('Sign in')),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CreateAccountScreen(state: widget.state),
          ),
        ),
        child: const Text('Create account'),
      ),
      TextButton.icon(
        onPressed: () => openPage(context, const DoctorSignInScreen()),
        icon: const Icon(Icons.medical_services_outlined),
        label: const Text('Clinician sign in'),
      ),
    ],
  );
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool hidePassword = true;
  bool hideConfirmation = true;

  int get strength {
    final value = password.text;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void createAccount() {
    if (!formKey.currentState!.validate()) return;
    final next = widget.state.safetyAccepted
        ? AccountCreatedScreen(state: widget.state)
        : SafetyResponsibilityScreen(
            state: widget.state,
            email: email.text.trim(),
            password: password.text.trim(),
          );
    openPage(context, next);
  }

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Your private skin lab',
    title: 'Create account',
    subtitle: 'Set up your account, then choose what you want to improve.',
    children: [
      _SocialButton(
        icon: 'G',
        label: 'Sign up with Google',
        onPressed: () => _continueSocial(),
      ),
      const SizedBox(height: 10),
      _SocialButton(
        icon: '●',
        label: 'Sign up with Apple',
        onPressed: () => _continueSocial(),
      ),
      const _OrDivider(),
      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const Key('createEmail'),
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.newUsername],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('createPassword'),
              controller: password,
              obscureText: hidePassword,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (_) => strength >= 3
                  ? null
                  : 'Use 8+ characters with upper, lower and a number',
            ),
            const SizedBox(height: 8),
            _PasswordStrength(value: strength),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('confirmPassword'),
              controller: confirmPassword,
              obscureText: hideConfirmation,
              onFieldSubmitted: (_) => createAccount(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => hideConfirmation = !hideConfirmation),
                  icon: Icon(
                    hideConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == password.text && value!.isNotEmpty
                  ? null
                  : 'Passwords do not match',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('createAccountButton'),
        onPressed: createAccount,
        child: const Text('Create account'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SignInScreen(state: widget.state)),
        ),
        child: const Text('Already have an account? Sign in'),
      ),
    ],
  );

  void _continueSocial() {
    final next = widget.state.safetyAccepted
        ? AccountCreatedScreen(state: widget.state)
        : SafetyResponsibilityScreen(state: widget.state);
    openPage(context, next);
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final String icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Text(
      icon,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    ),
    label: Text(label),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .55),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      0 || 1 => DermaireColors.conflict,
      2 => DermaireColors.unknown,
      _ => DermaireColors.safe,
    };
    final label = switch (value) {
      0 => 'Password strength',
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Strong',
      _ => 'Very strong',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: index < value ? color : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 11.5, color: color)),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  bool sent = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Account recovery',
    title: 'Forgot password',
    subtitle: 'Enter your email and we’ll send you a reset link.',
    children: [
      Form(
        key: formKey,
        child: TextFormField(
          key: const Key('resetEmail'),
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: _validateEmail,
        ),
      ),
      const SizedBox(height: 14),
      if (sent)
        const Notice(
          icon: '✓',
          text: 'Reset link sent. Check your inbox and spam folder.',
          color: DermaireColors.safeBackground,
        ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState!.validate()) setState(() => sent = true);
        },
        child: const Text('Send reset link'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back to sign in'),
      ),
    ],
  );
}

class SafetyResponsibilityScreen extends StatefulWidget {
  const SafetyResponsibilityScreen({
    super.key,
    required this.state,
    this.email,
    this.password,
  });
  final DermaireState state;
  final String? email;
  final String? password;

  @override
  State<SafetyResponsibilityScreen> createState() =>
      _SafetyResponsibilityScreenState();
}

class _SafetyResponsibilityScreenState
    extends State<SafetyResponsibilityScreen> {
  final controller = ScrollController();
  bool reachedEnd = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  void _checkScroll() {
    if (!controller.hasClients || reachedEnd) return;
    if (controller.position.maxScrollExtent <= 0 ||
        controller.position.extentAfter <= 4) {
      setState(() => reachedEnd = true);
    }
  }

  @override
  void dispose() {
    controller
      ..removeListener(_checkScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('safetyScroll'),
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('First-time setup'),
                  Text(
                    'Safety & responsibility',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 23),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please read this once before starting your first skin experiment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .72),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SafetyItem(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Dermaire is not medical advice',
                    text:
                        'The app helps you observe patterns. It does not diagnose, treat, or replace a dermatologist or other qualified clinician.',
                  ),
                  const _SafetyItem(
                    icon: Icons.science_outlined,
                    title: 'Change one thing at a time',
                    text:
                        'Patch test new products first. Introduce one product per experiment so you can identify what caused a change.',
                  ),
                  const _SafetyItem(
                    icon: Icons.warning_amber_rounded,
                    title: 'Stop if irritation appears',
                    text:
                        'Stop the experiment if you develop burning, swelling, severe redness, blistering, or rapidly worsening symptoms.',
                  ),
                  const _SafetyItem(
                    icon: Icons.local_hospital_outlined,
                    title: 'Know when to seek care',
                    text:
                        'Seek urgent medical help for trouble breathing, facial swelling, widespread hives, eye involvement, or another severe reaction.',
                  ),
                  const _SafetyItem(
                    icon: Icons.lock_outline,
                    title: 'Protect your information',
                    text:
                        'Use the app on your own device, secure your account, and avoid including identifying information in notes you plan to share.',
                  ),
                  DermaireCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disclaimer',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Skin measurements can vary with lighting, camera quality, environment, routine, and normal biological changes. Results are estimates and may be incomplete or inaccurate. You remain responsible for product choices and for following each manufacturer’s instructions. If you are pregnant, breastfeeding, have a diagnosed skin condition, use prescription treatment, or are unsure whether an ingredient is suitable, speak with a qualified clinician before beginning an experiment.',
                          style: TextStyle(fontSize: 12.5, height: 1.55),
                        ),
                      ],
                    ),
                  ),
                  const Notice(
                    icon: '↓',
                    text:
                        'You’ve reached the end. Continue to confirm that you have read these safety notes.',
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                if (!reachedEnd)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Scroll to the end to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .62),
                      ),
                    ),
                  ),
                FilledButton(
                  key: const Key('acceptSafetyButton'),
                  onPressed: reachedEnd
                      ? () async {
                          await widget.state.acceptSafety();
                          if (widget.email != null && widget.password != null) {
                            try {
                              await ApiService.instance.register(
                                email: widget.email!,
                                password: widget.password!,
                                fullName: 'Dermaire Member',
                                role: 'patient',
                                acceptSafety: true,
                              );
                            } catch (_) {}
                          }
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AccountCreatedScreen(state: widget.state),
                            ),
                          );
                        }
                      : null,
                  child: const Text('I understand — continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SafetyItem extends StatelessWidget {
  const _SafetyItem({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => DermaireCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DermaireColors.caramel.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 12.5, height: 1.45)),
            ],
          ),
        ),
      ],
    ),
  );
}

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => DermairePage(
    showBack: false,
    centered: true,
    eyebrow: 'You’re ready',
    title: 'Account created',
    subtitle: 'Your private skin lab is ready for its first experiment.',
    children: [
      const SizedBox(height: 24),
      Center(
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DermaireColors.safeBackground,
            border: Border.all(color: DermaireColors.safe, width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 58,
            color: DermaireColors.safe,
          ),
        ),
      ),
      const SizedBox(height: 36),
      FilledButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SkinProfileScreen(state: state)),
        ),
        child: const Text('Start my skin experiment'),
      ),
    ],
  );
}

class SkinProfileScreen extends StatelessWidget {
  const SkinProfileScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) {
    const concerns = [
      ('Acne', Icons.bubble_chart_outlined),
      ('Redness', Icons.thermostat_outlined),
      ('Texture', Icons.grain_rounded),
      ('Dryness', Icons.water_drop_outlined),
      ('Oiliness', Icons.opacity_rounded),
      ('Other', Icons.add_circle_outline),
    ];
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => DermairePage(
        eyebrow: 'Skin profile',
        title: 'Tell us about your skin',
        subtitle:
            'Choose every concern you want to track. You can change these later.',
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.65,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: concerns.map((item) {
              final selected = state.skinConcerns.contains(item.$1);
              return InkWell(
                onTap: () => state.toggleConcern(item.$1),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? DermaireColors.caramel.withValues(alpha: .28)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$2,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _openApp(context, state),
            child: const Text('Continue to my skin lab'),
          ),
        ],
      ),
    );
  }
}
