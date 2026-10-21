import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/config.dart';
import 'profile_controller.dart';

part 'profile_binding.dart';

class ProfileView extends GetView<ProfileViewController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.isRegistered<HomeViewController>() ? Get.find<HomeViewController>() : null;
    
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppText.h3.copyWith(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: controller.uploadPhoto,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColor.secondaryColor, width: 3),
                          ),
                          child: homeCtrl == null 
                            ? const CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, size: 40, color: Colors.grey),
                              )
                            : Obx(() {
                            final photoPath = homeCtrl.user.value?.profilePhoto;
                            if (photoPath != null && photoPath.isNotEmpty) {
                              return CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(
                                  '${Config.instance.baseUrl}/$photoPath',
                                ),
                              );
                            }
                            return const CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 40, color: Colors.grey),
                            );
                          }),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColor.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        homeCtrl == null
                          ? Text(
                              'User Name',
                              style: AppText.h3.copyWith(color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Obx(() => Text(
                              homeCtrl.user.value?.fullName ?? 'User Name',
                              style: AppText.h3.copyWith(color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                        const SizedBox(height: 4),
                        homeCtrl == null
                          ? Text(
                              '+855 00 000 000',
                              style: AppText.bodyMedium.copyWith(color: Colors.grey[600]),
                            )
                          : Obx(() => Text(
                              homeCtrl.user.value?.phoneNumber ?? '+855 00 000 000',
                              style: AppText.bodyMedium.copyWith(color: Colors.grey[600]),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Settings options
            _buildOptionGroup(
              title: 'Account Settings',
              options: [
                _buildOptionItem(
                  icon: Icons.badge_outlined,
                  title: 'Identity Information',
                  onTap: () {
                    _showIdentityInformation(context, homeCtrl);
                  },
                ),
                _buildOptionItem(
                  icon: Icons.person_outline, 
                  title: 'Edit Personal Information', 
                  onTap: () {
                    _showEditProfileDialog(context, homeCtrl);
                  },
                ),
                _buildOptionItem(icon: Icons.security_rounded, title: 'Security & PIN', onTap: () {}),
                _buildOptionItem(icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () {}),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildOptionGroup(
              title: 'Support',
              options: [
                _buildOptionItem(icon: Icons.help_outline_rounded, title: 'Help Center', onTap: () {}),
                _buildOptionItem(icon: Icons.info_outline_rounded, title: 'About Us', onTap: () {}),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.logout,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.redAccent.shade100, width: 1),
                  ),
                ),
                child: controller.isLoading.value 
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded),
                        const SizedBox(width: 8),
                        Text('Logout', style: AppText.h4.copyWith(color: Colors.redAccent)),
                      ],
                    ),
              )),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, HomeViewController? homeCtrl) {
    final TextEditingController firstNameCtrl = TextEditingController(text: homeCtrl?.user.value?.firstName ?? '');
    final TextEditingController lastNameCtrl = TextEditingController(text: homeCtrl?.user.value?.lastName ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateProfileInfo(firstNameCtrl.text, lastNameCtrl.text);
            },
            child: const Text('Save'),
          ),
        ],
      )
    );
  }

  void _showIdentityInformation(BuildContext context, HomeViewController? homeCtrl) {
    final user = homeCtrl?.user.value;
    final String nidNumber = user?.nidNumber ?? '';
    final String fullName = user?.nidFullName ?? user?.fullName ?? '';
    final String dob = user?.dateOfBirth ?? '';
    final String expiry = user?.expiryDate ?? '';
    final String gender = user?.gender ?? '';
    final String kycStatus = (user?.kycStatus ?? 'not_submitted').toLowerCase();
    final bool isApproved = kycStatus == 'approved';
    final String? nidFront = user?.nidFrontPath;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1249AD).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_outlined,
                            color: Color(0xFF1249AD), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identity Information',
                            style: AppText.h3.copyWith(
                                color: Colors.black87, fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'National ID & Verification Details',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Status Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isApproved
                        ? const Color(0xFF81C784)
                        : const Color(0xFFFFB74D),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isApproved
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                      color: isApproved
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproved
                                ? 'Identity Verified'
                                : 'Verification Required',
                            style: TextStyle(
                              color: isApproved
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isApproved
                                ? 'Your National ID has been scanned and biometrically verified.'
                                : 'Please complete your NID scan and face verification.',
                            style: TextStyle(
                              color: isApproved
                                  ? const Color(0xFF388E3C)
                                  : const Color(0xFFEF6C00),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // NID Card Preview (if exists)
              if (nidFront != null && nidFront.isNotEmpty) ...[
                Text('Document Photo',
                    style: AppText.h4.copyWith(
                        color: Colors.grey.shade700, fontSize: 14)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      '${Config.instance.baseUrl}/$nidFront',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 40, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Info Fields
              Text('National ID Details',
                  style: AppText.h4.copyWith(
                      color: Colors.grey.shade700, fontSize: 14)),
              const SizedBox(height: 10),
              _buildIdentityTile(
                  Icons.numbers_rounded,
                  'NID Number',
                  nidNumber.isNotEmpty ? nidNumber : '-'),
              _buildIdentityTile(
                  Icons.person_rounded,
                  'Full Name on NID',
                  fullName.isNotEmpty ? fullName : '-'),
              _buildIdentityTile(
                  Icons.cake_rounded,
                  'Date of Birth',
                  dob.isNotEmpty ? dob : '-'),
              _buildIdentityTile(
                  Icons.calendar_today_rounded,
                  'Expiry Date',
                  expiry.isNotEmpty ? expiry : '-'),
              _buildIdentityTile(
                  Icons.wc_rounded,
                  'Gender',
                  gender.isNotEmpty ? gender : '-'),
              _buildIdentityTile(
                  Icons.shield_outlined,
                  'Verification Method',
                  'National ID & Facial Recognition'),
              const SizedBox(height: 24),
              if (!isApproved)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.kycDocument);
                    },
                    icon: const Icon(Icons.document_scanner_rounded),
                    label: const Text('Verify Identity with NID'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1249AD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildIdentityTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1249AD)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptionGroup({required String title, required List<Widget> options}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: AppText.h4.copyWith(color: Colors.grey[800]),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: options,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColor.secondaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppText.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}