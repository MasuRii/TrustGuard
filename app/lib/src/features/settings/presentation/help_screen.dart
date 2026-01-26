import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _privacyPolicy;
  String? _userGuide;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final privacyPolicy = await rootBundle.loadString(
      'assets/docs/privacy_policy.md',
    );
    final userGuide = await rootBundle.loadString('assets/docs/user_guide.md');

    // Package info might not be available in all environments, so we handle it gracefully
    String version;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      version = '1.0.0+1';
    }

    if (mounted) {
      setState(() {
        _privacyPolicy = privacyPolicy;
        _userGuide = userGuide;
        _version = version;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Privacy'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'User Guide'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkdownView(_userGuide),
          _buildMarkdownView(_privacyPolicy),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TrustGuard v$_version',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Made with ❤️ offline',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownView(String? content) {
    if (content == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Markdown(
      data: content,
      styleSheet: MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      ).copyWith(p: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
