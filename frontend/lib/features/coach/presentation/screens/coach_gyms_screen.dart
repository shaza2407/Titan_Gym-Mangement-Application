import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/coach_gyms_controller.dart';
import '../widgets/gyms_tab_stats.dart';
import '../widgets/gyms_segmented_control.dart';
import '../widgets/gyms_list_view.dart';
import '../widgets/announcements_list_view.dart';

class CoachGymsScreen extends StatefulWidget {
  final String token;
  final VoidCallback onBack;
  final CoachGymsController controller;

  const CoachGymsScreen({
    super.key,
    required this.token,
    required this.onBack,
    required this.controller,
  });

  @override
  State<CoachGymsScreen> createState() => CoachGymsScreenState();
}

class CoachGymsScreenState extends State<CoachGymsScreen>
    with WidgetsBindingObserver {
  int _selectedTab = 0;
  late CoachGymsController _ctrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = widget.controller;
    _ctrl.addListener(_onError);
  }

  void _onError() {
    if (_ctrl.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ctrl.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      _ctrl.errorMessage = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.removeListener(_onError);
    // No dispose the controller itself — dashboard owns it
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ctrl.loadAll(widget.token);
    }
  }

  void _onDataChanged() => _ctrl.loadAll(widget.token);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<CoachGymsController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: widget.onBack,
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Gyms',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connected gyms and announcements',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadAll(widget.token),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GymsTabStats(ctrl: ctrl),
                          const SizedBox(height: 24),
                          GymsSegmentedControl(
                            selectedIndex: _selectedTab,
                            onChanged: (index) =>
                                setState(() => _selectedTab = index),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedTab == 0)
                            GymsListView(
                              ctrl: ctrl,
                              token: widget.token,
                              onDataChanged: _onDataChanged,
                            ),
                          if (_selectedTab == 1)
                            AnnouncementsListView(ctrl: ctrl),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
