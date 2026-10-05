import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';

class AddJobScreen extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? existingJob;

  const AddJobScreen({
    super.key,
    this.jobId,
    this.existingJob,
  });

  bool get isEditMode => jobId != null && existingJob != null;

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final salaryController = TextEditingController();

  String selectedJobType = 'Full Time';
  String selectedCategory = JobCategories.fallback;
  bool isLoading = false;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color darkText = const Color(0xFF1F2937);
  final Color greyText = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode) {
      final job = widget.existingJob!;

      titleController.text = job['title']?.toString() ?? '';
      companyController.text = job['company']?.toString() ?? '';
      locationController.text = job['location']?.toString() ?? '';
      descriptionController.text =
          job['description']?.toString() ?? '';
      salaryController.text = job['salary']?.toString() ?? '';

      final jobType = job['jobType']?.toString();

      if (jobType != null &&
          [
            'Full Time',
            'Part Time',
            'Internship',
            'Contract',
          ].contains(jobType)) {
        selectedJobType = jobType;
      }

      final category = job['category']?.toString();

      if (category != null && JobCategories.all.contains(category)) {
        selectedCategory = category;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    companyController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SAVE JOB
  // ==========================================================

  Future<void> saveJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final jobData = {
        'title': titleController.text.trim(),
        'company': companyController.text.trim(),
        'location': locationController.text.trim(),
        'description': descriptionController.text.trim(),
        'salary': salaryController.text.trim(),
        'jobType': selectedJobType,
        'category': selectedCategory,
      };

      if (widget.isEditMode) {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .update({
          ...jobData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newJob = await FirebaseFirestore.instance
            .collection('jobs')
            .add({
          ...jobData,
          'publisherId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // NOTIFICATIONS: tell everyone subscribed to this category.
        unawaited(
          NotificationService.instance.notifyNewJobPosted(
            jobId: newJob.id,
            title: titleController.text.trim(),
            company: companyController.text.trim(),
            category: selectedCategory,
          ),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isEditMode
                      ? 'Job updated successfully!'
                      : 'Job added successfully!',
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isEditMode
                      ? 'Failed to update job:\n$e'
                      : 'Failed to add job:\n$e',
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryBlue,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryBlue,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ==========================================================
  // FIELD LABEL
  // ==========================================================

  Widget fieldLabel(
      String title, {
        bool required = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION CARD
  // ==========================================================

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEdit
                    ? Icons.edit_outlined
                    : Icons.add_business_outlined,
                color: primaryBlue,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Edit Job' : 'Add New Job',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          35,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 850,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryBlue,
                          const Color(0xFF1976D2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? 'Update Job Posting'
                                    : 'Create a New Job',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEdit
                                    ? 'Update the information for this job posting.'
                                    : 'Add a new opportunity for CareerWise users.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // BASIC INFORMATION
                  // ==================================================

                  sectionCard(
                    title: 'Basic Information',
                    subtitle:
                    'Enter the main details about the job.',
                    icon: Icons.info_outline,
                    children: [
                      fieldLabel('Job Title'),

                      TextFormField(
                        controller: titleController,
                        decoration: inputDecoration(
                          hint: 'e.g. Software Engineer',
                          icon: Icons.work_outline,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter job title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      fieldLabel('Company'),

                      TextFormField(
                        controller: companyController,
                        decoration: inputDecoration(
                          hint: 'e.g. ABC Technologies',
                          icon: Icons.business_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter company name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      fieldLabel('Location'),

                      TextFormField(
                        controller: locationController,
                        decoration: inputDecoration(
                          hint: 'e.g. Colombo, Sri Lanka',
                          icon: Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // JOB DETAILS
                  // ==================================================

                  sectionCard(
                    title: 'Job Details',
                    subtitle:
                    'Set the employment type and salary.',
                    icon: Icons.badge_outlined,
                    children: [
                      fieldLabel('Job Type'),

                      DropdownButtonFormField<String>(
                        value: selectedJobType,
                        decoration: inputDecoration(
                          hint: 'Select job type',
                          icon: Icons.schedule_outlined,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        items: const [
                          DropdownMenuItem(
                            value: 'Full Time',
                            child: Text('Full Time'),
                          ),
                          DropdownMenuItem(
                            value: 'Part Time',
                            child: Text('Part Time'),
                          ),
                          DropdownMenuItem(
                            value: 'Internship',
                            child: Text('Internship'),
                          ),
                          DropdownMenuItem(
                            value: 'Contract',
                            child: Text('Contract'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedJobType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      fieldLabel('Job Category'),

                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        decoration: inputDecoration(
                          hint: 'Select job category',
                          icon: Icons.category_outlined,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        items: JobCategories.all.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      fieldLabel('Salary'),

                      TextFormField(
                        controller: salaryController,
                        decoration: inputDecoration(
                          hint: 'e.g. Rs. 100,000 - 150,000',
                          icon: Icons.payments_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter salary';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  sectionCard(
                    title: 'Job Description',
                    subtitle:
                    'Describe the role, responsibilities and requirements.',
                    icon: Icons.description_outlined,
                    children: [
                      fieldLabel('Description'),

                      TextFormField(
                        controller: descriptionController,
                        maxLines: 8,
                        decoration: inputDecoration(
                          hint:
                          'Enter job description, responsibilities, requirements and skills...',
                          icon: Icons.article_outlined,
                        ).copyWith(
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter job description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit
                                ? 'Updating Job...'
                                : 'Adding Job...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEdit
                                ? Icons.save_outlined
                                : Icons.add_business_outlined,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEdit
                                ? 'Update Job'
                                : 'Add Job',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'All fields marked with * are required',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}