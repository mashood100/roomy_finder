import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String _password = '';
  bool _showPassword = false;
  bool _isLoading = false;

  Future<void> _handleDeleteAccountPressed(String password) async {
    if (password != AppController.me.password) {
      showToast("Incorrect password");
      return;
    }

    try {
      setState(() => _isLoading = true);

      final res = await ApiService.getDio.post(
        "/profile/delete-account",
        data: {"password": password, "email": AppController.me.email},
      );

      if (res.statusCode == 200) {
        showToast(res.data["message"]);
        await AppController.instance.logout();
        Get.offAllNamed('/login');
      } else {
        showToast(res.data["message"]);
      }
    } catch (e) {
      Get.log("$e");
      showToast("Something went wrong. Please try again later");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const text1 = 'Please note that by deleting your account, '
        'all your personal information and advertisements '
        'will be permanently removed from our system and '
        'cannot be recovered. We strongly recommend withdrawing '
        'any remaining funds from your account before'
        ' proceeding with this action, as ';

    const text2 = "Roomy Finder will not be able to refund"
        " any money to deleted accounts.";
    return WillPopScope(
      onWillPop: () async => _isLoading ? false : true,
      child: Scaffold(
        appBar: AppBar(title: const Text("Delete account")),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const Text(
                      "Attention: Account Deletion Notice",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.red),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Text.rich(
                        TextSpan(children: [
                          TextSpan(text: text1),
                          TextSpan(
                            text: text2,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "Enter your password",
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      onChanged: (val) => _password = val,
                      obscureText: !_showPassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: _isLoading
                            ? null
                            : () {
                                _handleDeleteAccountPressed(_password);
                              },
                        child: const Text(
                          "CONFIRM ACCOUNT DELETION",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  alignment: Alignment.center,
                  color: Colors.grey.withOpacity(0.3),
                  child: CircularProgressIndicator(
                    color: Colors.grey.withOpacity(0.8),
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
