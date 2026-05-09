import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const accent = Color(0xFF2563EB);

  Widget _featureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _workflowStep(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(description, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    final quickStats = [
      {'label': 'Live dashboards', 'value': '01'},
      {'label': 'Service channels', 'value': '04'},
      {'label': 'Workflow stages', 'value': '05'},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'All-in-one service operations platform',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Manage Complaints, Appointments, and Support — All in One Platform',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Streamline service delivery with real-time communication, structured workflows, and performance tracking.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  minimumSize: const Size(180, 50),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                ),
                                child: const Text('Get Started'),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(160, 50),
                                ),
                                onPressed: () => Scrollable.ensureVisible(
                                  Scrollable.of(context).context,
                                ),
                                child: const Text('Request Demo'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Quick stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: quickStats
                                .map(
                                  (s) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _statCard(
                                        context,
                                        s['label']!,
                                        s['value']!,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    if (isWide)
                      const SizedBox(width: 20)
                    else
                      const SizedBox(height: 24),
                    // Visual preview
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Live operations dashboard',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // simple mock preview rows
                            for (var i = 0; i < 4; i++)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Features grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _featureCard(
                          context,
                          Icons.mark_chat_unread_outlined,
                          'Complaint Management',
                          'Submit, track, and resolve complaints with clear ownership.',
                        ),
                        _featureCard(
                          context,
                          Icons.calendar_month_outlined,
                          'Appointment Scheduling',
                          'Request and manage appointments with calendar views.',
                        ),
                        _featureCard(
                          context,
                          Icons.rule_folder_outlined,
                          'Service Templates',
                          'Create reusable templates for consistent service delivery.',
                        ),
                        _featureCard(
                          context,
                          Icons.support_agent_outlined,
                          'Real-time Helpdesk',
                          'Chat, call, and collaborate with support teams live.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Workflow steps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _workflowStep(
                      context,
                      Icons.upload_file,
                      'Submit Request',
                      'Users raise a complaint, appointment, or ticket from one entry point.',
                    ),
                    const SizedBox(height: 12),
                    _workflowStep(
                      context,
                      Icons.list_alt,
                      'System Logs & Assigns',
                      'Requests are routed and assigned to the right team.',
                    ),
                    const SizedBox(height: 12),
                    _workflowStep(
                      context,
                      Icons.handyman,
                      'Staff Handles Request',
                      'Officers update progress and attach notes.',
                    ),
                    const SizedBox(height: 12),
                    _workflowStep(
                      context,
                      Icons.chat_bubble_outline,
                      'Real-Time Communication',
                      'Users and support teams exchange messages and updates.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // CTA footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to get started?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          child: const Text('Create Account'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contact us: support@example.com',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
