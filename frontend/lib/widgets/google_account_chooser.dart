import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GoogleAccount {
  final String name;
  final String email;
  final Color avatarColor;

  GoogleAccount({
    required this.name,
    required this.email,
    required this.avatarColor,
  });
}

class GoogleAccountChooserDialog extends StatefulWidget {
  const GoogleAccountChooserDialog({super.key});

  @override
  State<GoogleAccountChooserDialog> createState() => _GoogleAccountChooserDialogState();
}

class _GoogleAccountChooserDialogState extends State<GoogleAccountChooserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isUsingOtherAccount = false;

  final List<GoogleAccount> _mockAccounts = [
    GoogleAccount(name: 'Nang Lorr', email: 'nanglorr@gmail.com', avatarColor: Colors.orange.shade800),
    GoogleAccount(name: 'Tamedak loyak Nn', email: 'tamedakloyaknn@gmail.com', avatarColor: Colors.teal.shade700),
    GoogleAccount(name: 'Buntot12 Gede', email: 'buntotgede@gmail.com', avatarColor: Colors.lightGreen.shade700),
    GoogleAccount(name: 'HakikiFr HakikiFr', email: 'hhakikifr@gmail.com', avatarColor: Colors.pink.shade600),
    GoogleAccount(name: 'Faturrahman Faturrahman', email: 'faturrahmanfaturrahman80@gmail.com', avatarColor: Colors.blueGrey.shade600),
    GoogleAccount(name: 'Loncos12 Bae', email: 'loncosbae@gmail.com', avatarColor: Colors.lime.shade800),
    GoogleAccount(name: 'Samal Macang', email: 'samalmacang406@gmail.com', avatarColor: Colors.purple.shade600),
    GoogleAccount(name: 'DukuDurian 01', email: 'dukudurian4@gmail.com', avatarColor: Colors.deepOrange.shade800),
    GoogleAccount(name: 'Sekdol Kacau', email: 'kacausekdol@gmail.com', avatarColor: Colors.green.shade700),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _selectAccount(String name, String email) {
    Navigator.of(context).pop({'name': name, 'email': email});
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 700;

    // Dark Google Theme Colors
    const backgroundColor = Color(0xFF131314);
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFFC4C7C5);
    const googleBlue = Color(0xFF8AB4F8);
    const dividerColor = Color(0xFF444746);

    Widget headerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google Logo mockup or text
        Row(
          children: [
            const Text(
              'G',
              style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
            ),
            const Text(
              'o',
              style: TextStyle(color: Color(0xFFEA4335), fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
            ),
            const Text(
              'o',
              style: TextStyle(color: Color(0xFFFBBC05), fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
            ),
            const Text(
              'g',
              style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
            ),
            const Text(
              'l',
              style: TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
            ),
            const Text(
              'e',
              style: TextStyle(color: Color(0xFFEA4335), fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Outfit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _isUsingOtherAccount ? 'Login Google' : 'Pilih akun',
          style: const TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.normal,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(color: textSecondary, fontSize: 14, fontFamily: 'Outfit'),
            children: [
              TextSpan(text: 'Lanjutkan ke '),
              TextSpan(
                text: 'Google Antigravity',
                style: TextStyle(color: googleBlue, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );

    Widget accountListSection = ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _mockAccounts.length + 1,
      itemBuilder: (context, index) {
        if (index == _mockAccounts.length) {
          // Use another account option
          return Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: dividerColor, width: 0.5),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: textSecondary, width: 1.5),
                ),
                child: const Icon(
                  CupertinoIcons.person,
                  color: textSecondary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Gunakan akun lain',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Outfit',
                ),
              ),
              onTap: () {
                setState(() {
                  _isUsingOtherAccount = true;
                });
              },
            ),
          );
        }

        final account = _mockAccounts[index];
        final String initial = account.name.isNotEmpty ? account.name[0].toUpperCase() : 'G';

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: dividerColor, width: 0.5),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: account.avatarColor,
              radius: 20,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            title: Text(
              account.name,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
              ),
            ),
            subtitle: Text(
              account.email,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontFamily: 'Outfit',
              ),
            ),
            onTap: () => _selectAccount(account.name, account.email),
          ),
        );
      },
    );

    Widget customAccountFormSection = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gunakan akun Google Anda',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: textPrimary, fontFamily: 'Outfit'),
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              labelStyle: const TextStyle(color: textSecondary, fontFamily: 'Outfit'),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: googleBlue, width: 1.5),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama lengkap harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: textPrimary, fontFamily: 'Outfit'),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Alamat Email Google',
              labelStyle: const TextStyle(color: textSecondary, fontFamily: 'Outfit'),
              hintText: 'nama@gmail.com',
              hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: googleBlue, width: 1.5),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email harus diisi';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Alamat email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isUsingOtherAccount = false;
                    _nameController.clear();
                    _emailController.clear();
                  });
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(color: googleBlue, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _selectAccount(_nameController.text.trim(), _emailController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: googleBlue,
                  foregroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lanjutkan',
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Desktop/Large Screen side-by-side or mobile single column
    Widget dialogBody;
    if (isLargeScreen) {
      dialogBody = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: headerSection,
            ),
          ),
          const VerticalDivider(color: dividerColor, width: 1),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: _isUsingOtherAccount
                  ? customAccountFormSection
                  : SizedBox(
                      height: 400,
                      child: accountListSection,
                    ),
            ),
          ),
        ],
      );
    } else {
      dialogBody = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            headerSection,
            const SizedBox(height: 24),
            const Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),
            _isUsingOtherAccount
                ? customAccountFormSection
                : SizedBox(
                    height: 350,
                    child: accountListSection,
                  ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: dividerColor, width: 1),
      ),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: isLargeScreen ? 750 : double.infinity,
        padding: const EdgeInsets.all(32.0),
        child: dialogBody,
      ),
    );
  }
}
