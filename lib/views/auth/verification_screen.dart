import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kutuku/router/app_router.dart';
import 'package:kutuku/widget/success_bottom_sheet.dart';
import 'package:lottie/lottie.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final int pintLength = 4;
  late final List<TextEditingController> _pinControllers;
  late final List<FocusNode> _focusNode;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _pinControllers = List.generate(pintLength, (_) => TextEditingController());
    _focusNode = List.generate(pintLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _focusNode) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentPin => _pinControllers.map((c) => c.text).join();

  Future<void> _verifyPin() async {
    //defensive check
    if (_currentPin.length != pintLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter yhr complete $pintLength-digit PIN'),
        ),
      );
      return;
    }

    //hide the keyboard and lock UI
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
    });
    try {
      // stimulate network call
      await Future.delayed(const Duration(seconds: 2));
      // Example: If you had server validation ,you'd check its result here
      final success = true;
      setState(() {
        _isVerifying = false;
      });
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid PIN , please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed-check connection.')),
      );
    }
  }

  void _showSuccessDialog() {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SuccessBottomSheet(
          onContinue: () {
            context.pop();
            context.goNamed(AppRouter.home);
          },
        );
      },
    );
  }

  Widget _buildPinFields(int index) {
    return SizedBox(
      width: 62,
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _focusNode[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.length == 1) {
            //Move focus to the next field if available or unfocus if last
            if (index + 1 != pintLength) {
              _focusNode[index + 1].requestFocus();
            } else {
              _focusNode[index].unfocus();
            }
          } else if (value.isEmpty) {
            // if user deleted value ,move focus back if possible
            if (index > 0) {
              _focusNode[index - 1].requestFocus();
            }
          }
          setState(() {});
        },
        onSubmitted: (_) {
          // if they press keyboard's submit button on last field , try verify
          if (_currentPin.length == pintLength) _verifyPin();
        },
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _currentPin.length == pintLength;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: Lottie.asset('assets/animation/validation.json'),
              ),

              Text(
                'Enter the 4-digit code sent to your email',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(pintLength, (i) => _buildPinFields(i)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (_isVerifying || !isComplete) ? null : _verifyPin,
                      child:
                          _isVerifying
                              ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text('Verify'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed:
                      _isVerifying
                          ? null
                          : () {
                            // provides resend logic here.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Resend code tapped (simulated)'),
                              ),
                            );
                          },
                  child: Text('Resend code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
