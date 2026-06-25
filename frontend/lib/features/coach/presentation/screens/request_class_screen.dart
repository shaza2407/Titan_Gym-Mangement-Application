import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/coach_schedule_controller.dart';

// --- Import widgets ---
import '../widgets/request_form_text_field.dart';
import '../widgets/request_form_dropdown.dart';
import '../widgets/request_form_pickers.dart';
import '../widgets/request_form_buttons.dart';

class RequestClassScreen extends StatefulWidget {
  final String token;
  final CoachScheduleController controller;

  const RequestClassScreen({super.key, required this.token, required this.controller});

  @override
  State<RequestClassScreen> createState() => _RequestClassScreenState();
}

class _RequestClassScreenState extends State<RequestClassScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadGyms(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<CoachScheduleController>(
        builder: (context, c, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request New Class', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Submit a request to the gym admin', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RequestFormTextField(
                      label: 'Class Name *',
                      controller: c.classNameController,
                      hint: 'e.g., Morning Yoga',
                    ),
                    
                    RequestFormDropdown(ctrl: c),
                    RecurringSwitchField(ctrl: c),
                    DatePickerField(ctrl: c),
                    TimePickerField(ctrl: c),

                    Row(
                      children: [
                        Expanded(
                          child: RequestFormTextField(
                            label: 'Duration (min)',
                            controller: c.durationController,
                            hint: '45',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RequestFormTextField(
                            label: 'Max Capacity *',
                            controller: c.maxCapacityController,
                            hint: '20',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    RequestFormTextField(
                      label: 'Reason (Optional)',
                      controller: c.reasonController,
                      hint: 'Why is this class needed?',
                      maxLines: 3,
                    ),

                    RequestFormButtons(ctrl: c, token: widget.token),
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