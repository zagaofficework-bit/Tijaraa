import 'dart:io';

import 'package:Tijaraa/data/repositories/item/job_repository.dart';
import 'package:Tijaraa/utils/helper_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// ====================================================================
// 1. DATA MODEL (DynamicEntry)
// ====================================================================
class DynamicEntry {
  TextEditingController titleController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  TextEditingController extraController1 =
      TextEditingController(); // e.g., Location/Dates or Grades/Honors
  TextEditingController extraController2 =
      TextEditingController(); // e.g., Measurable Achievements
  Key key = UniqueKey();

  DynamicEntry({
    String title = '',
    String detail = '',
    String extra1 = '',
    String extra2 = '',
  }) {
    titleController.text = title;
    detailController.text = detail;
    extraController1.text = extra1;
    extraController2.text = extra2;
  }
}

class MyJobProfileScreen extends StatefulWidget {
  const MyJobProfileScreen({super.key});

  @override
  State<MyJobProfileScreen> createState() => _MyJobProfileScreenState();
}

class _MyJobProfileScreenState extends State<MyJobProfileScreen> {
  // ====================================================================
  // 2. CONTROLLERS & STATE
  // ====================================================================

  // --- Simple Field Controllers ---
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final linkedInController = TextEditingController();
  final portfolioController = TextEditingController();
  final headlineController = TextEditingController();
  final summaryController = TextEditingController();
  final skillsController = TextEditingController();
  final visaIdController = TextEditingController();

  // --- Dynamic List Controllers ---
  List<DynamicEntry> workExperienceList = [DynamicEntry()];
  List<DynamicEntry> educationList = [DynamicEntry()];
  List<DynamicEntry> projectsList = [DynamicEntry()];
  List<DynamicEntry> volunteerList = [DynamicEntry()];

  // --- State Variables ---
  File? selectedResume;
  bool isExtracting = false;
  bool isSaving = false;
  bool isFetching = false;

  final JobRepository jobRepo = JobRepository();

  // ====================================================================
  // 3. LIFECYCLE METHODS
  // ====================================================================

  @override
  void initState() {
    super.initState();
    fetchUserJobProfile();
  }

  @override
  void dispose() {
    // Dispose simple controllers
    nameController.dispose();
    locationController.dispose();
    emailController.dispose();
    phoneController.dispose();
    linkedInController.dispose();
    portfolioController.dispose();
    headlineController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    visaIdController.dispose();

    // Dispose dynamic list controllers
    _disposeDynamicList(workExperienceList);
    _disposeDynamicList(educationList);
    _disposeDynamicList(projectsList);
    _disposeDynamicList(volunteerList);

    super.dispose();
  }

  // ====================================================================
  // 4. DATA MANAGEMENT & CORE LOGIC
  // ====================================================================

  // --- Utility: Dynamic List Management ---

  void _disposeDynamicEntry(DynamicEntry entry) {
    entry.titleController.dispose();
    entry.detailController.dispose();
    entry.extraController1.dispose();
    entry.extraController2.dispose();
  }

  void _disposeDynamicList(List<DynamicEntry> list) {
    for (var entry in list) {
      _disposeDynamicEntry(entry);
    }
  }

  void _addEntry(
    List<DynamicEntry> list, {
    String title = '',
    String detail = '',
  }) {
    setState(() {
      list.add(DynamicEntry(title: title, detail: detail));
    });
  }

  void _removeEntry(List<DynamicEntry> list, DynamicEntry entry) {
    setState(() {
      list.remove(entry);
      _disposeDynamicEntry(entry);
    });
  }

  String _formatListForSubmission(List<DynamicEntry> list, String type) {
    if (type == 'work') {
      return list
          .map(
            (e) =>
                "TITLE: ${e.titleController.text} | COMPANY: ${e.detailController.text} | LOC/DATES: ${e.extraController1.text} | ACHIEVEMENTS: ${e.extraController2.text}",
          )
          .join('\n---\n');
    } else if (type == 'education') {
      return list
          .map(
            (e) =>
                "DEGREE: ${e.titleController.text} | INSTITUTION: ${e.detailController.text} | GRADES/HONORS: ${e.extraController1.text}",
          )
          .join('\n---\n');
    }
    return list
        .map((e) => "${e.titleController.text} | ${e.detailController.text}")
        .join('\n---\n');
  }

  // --- Utility: Resume Parsing Helpers (Executed in Isolate) ---

  /// Background isolate parser for text PDFs using syncfusion_flutter_pdf.
  static String parsePdfText(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final pdf = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(
        pdf,
      ).extractText().replaceAll('\r\n', ' ').replaceAll('\n', ' ');
      pdf.dispose();
      return text;
    } catch (e) {
      if (kDebugMode) {
        print("PDF Parsing Error: $e");
      }
      rethrow;
    }
  }

  /// Placeholder for Word parsing (executed in Isolate).
  static Future<String> parseWordText(String path) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return "WORD_DOC_SELECTED_FLAG";
  }

  // --- Utility: Text Extraction (Run on main thread or with compute) ---

  /// Regex-based text extractor for simple fields.
  String _extract(String text, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim() ?? match?.group(0)?.trim() ?? "";
  }

  /// Extracts full text between section headers.
  String _extractSection(String text, String start, String end) {
    final regex = RegExp(
      '$start\\s*(.*?)\\s*$end',
      caseSensitive: false,
      dotAll: true,
    );
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? "";
  }

  /// Helper to pre-fill dynamic lists from a parsed text block (Heuristic-based).
  void _prefillDynamicListLocal(List<DynamicEntry> list, String parsedText) {
    if (parsedText.isEmpty) return;

    _disposeDynamicList(list);
    list.clear();

    final blocks = parsedText
        .split(RegExp(r'\n\s*\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    for (var block in blocks) {
      final lines = block.split('\n').map((e) => e.trim()).toList();
      final title = lines.isNotEmpty ? lines[0] : '';
      final extra1 = lines.length > 1 ? lines[1] : '';
      final detail = lines.length > 2 ? lines.sublist(2).join('\n') : '';

      list.add(DynamicEntry(title: title, extra1: extra1, detail: detail));
    }

    if (list.isEmpty) {
      list.add(DynamicEntry());
    }
  }

  // --- Main I/O & State Handlers ---

  Future<void> fetchUserJobProfile() async {
    // Placeholder for fetching existing user data
    setState(() => isFetching = true);
    // await Future.delayed(const Duration(seconds: 1)); // Simulate fetch time
    setState(() => isFetching = false);
  }

  Future<void> pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc'],
    );

    if (result != null && result.files.single.path != null) {
      selectedResume = File(result.files.single.path!);
      await extractResumeInBackground(
        selectedResume!,
      ); // Proceed to attempt parsing
    }
  }

  Future<void> extractResumeInBackground(File file) async {
    setState(() => isExtracting = true);

    try {
      final String path = file.path;
      final String extension = path.split('.').last.toLowerCase();
      late String text = "";

      // 1. Extract raw text from file based on extension
      if (extension == 'pdf') {
        text = await compute(parsePdfText, path);
      } else if (extension == 'docx' || extension == 'doc') {
        // --- Word File Handling (Shows manual warning and exits full extraction) ---
        await compute(parseWordText, path);
        HelperUtils.showSnackBarMessage(
          context,
          " Word file detected. Auto-fill is limited; please fill manually.",
        );
        return; // EXIT here for Word files
      } else {
        throw Exception("Unsupported file type: $extension");
      }

      // --- PDF/Successful Text Extraction Logic ---
      if (text.trim().isEmpty) {
        throw Exception(
          "No text found in PDF. Is the file text-searchable (not scanned)?",
        );
      }

      // 2. Simple Field Extraction (Runs only for successful text)
      final name = _extract(
        text,
        r"^(.*?)\s\s*[^a-z0-9]",
      ).replaceAll(RegExp(r"[^\w\s]|\d"), '').trim();
      final email = _extract(
        text,
        r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}",
      );
      final phone = _extract(
        text,
        r"(\+?\d{1,4}[.\-\s]?\d{1,4}[.\-\s]?\d{4,10})",
      );
      final linkedIn = _extract(
        text,
        r"(https?:\/\/(?:www\.)?linkedin\.com\/in\/[^\s]+)",
      );

      // 3. Section Extraction for dynamic fields (and setState)
      final summary = _extractSection(
        text,
        r"(?:Summary|Objective|Profile)(?:[\s\n]*)",
        r"(?:Experience|Work Experience|Skills|Education)",
      );
      final skills = _extractSection(
        text,
        r"(?:Skills?|Technical Skills)(?:[\s\n]*)",
        r"(?:Education|Projects|Volunteer|Languages)",
      );
      final workExpRaw = _extractSection(
        text,
        r"(?:Work Experience|Experience|Professional Experience)(?:[\s\n]*)",
        r"(?:Education|Skills|Projects|Volunteer)",
      );
      final educationRaw = _extractSection(
        text,
        r"(?:Education|Academic History)(?:[\s\n]*)",
        r"(?:Projects|Volunteer|Visa)",
      );
      final projectsRaw = _extractSection(
        text,
        r"(?:Projects?|Relevant Projects)(?:[\s\n]*)",
        r"(?:Volunteer|Visa|$)",
      );
      final volunteerRaw = _extractSection(
        text,
        r"(?:Volunteer Experience|Volunteering)(?:[\s\n]*)",
        r"(?:Visa|$)",
      );

      setState(() {
        if (name.isNotEmpty) nameController.text = name;
        if (email.isNotEmpty) emailController.text = email;
        if (phone.isNotEmpty) phoneController.text = phone;
        if (linkedIn.isNotEmpty) linkedInController.text = linkedIn;
        if (summary.isNotEmpty) summaryController.text = summary;
        if (skills.isNotEmpty) skillsController.text = skills;

        _prefillDynamicListLocal(workExperienceList, workExpRaw);
        _prefillDynamicListLocal(educationList, educationRaw);
        _prefillDynamicListLocal(projectsList, projectsRaw);
        _prefillDynamicListLocal(volunteerList, volunteerRaw);
      });

      HelperUtils.showSnackBarMessage(
        context,
        " Resume data extracted locally. Please review fields for accuracy.",
      );
    } catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        " Local parsing failed: ${e.toString()}. Try another file or use the form manually.",
      );
    } finally {
      setState(() => isExtracting = false);
    }
  }

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(context, "Name and Email are required!");
      return;
    }

    setState(() => isSaving = true);
    try {
      final data = {
        // Simple fields
        "name": nameController.text.trim(),
        "location": locationController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "linkedin": linkedInController.text.trim(),
        "portfolio_url": portfolioController.text.trim(),
        "headline": headlineController.text.trim(),
        "summary": summaryController.text.trim(),
        "skills": skillsController.text.trim(),
        "visa_id": visaIdController.text.trim(),

        // Dynamic Sections (Formatted)
        "work_experience": _formatListForSubmission(workExperienceList, 'work'),
        "education": _formatListForSubmission(educationList, 'education'),
        "projects": _formatListForSubmission(projectsList, 'project'),
        "volunteer_experience": _formatListForSubmission(
          volunteerList,
          'volunteer',
        ),
      };

      final response = await jobRepo.applyJobApplication(data, selectedResume);

      HelperUtils.showSnackBarMessage(
        context,
        response['message'] ?? "Profile saved successfully!",
      );
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, "Failed to save: $e");
    } finally {
      setState(() => isSaving = false);
    }
  }

  // ====================================================================
  // 5. UI BUILDING HELPERS
  // ====================================================================

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    int lines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicEntryCard(
    List<DynamicEntry> list,
    DynamicEntry entry,
    String type,
  ) {
    List<Widget> fields = [];

    if (type == 'work') {
      fields = [
        _field(
          entry.titleController,
          "Job Title",
          hint: "e.g., Senior Software Engineer",
        ),
        _field(
          entry.detailController,
          "Name of Company",
          hint: "e.g., Tech Innovations Inc.",
        ),
        _field(
          entry.extraController1,
          "Location & Dates (MM/YYYY)",
          hint: "e.g., New York, NY | 01/2020 - 12/2024",
        ),
        _field(
          entry.extraController2,
          "Measurable Achievements & Responsibilities",
          lines: 4,
          hint: "Quantify your impact (e.g., Increased sales by 15%...)",
        ),
      ];
    } else if (type == 'education') {
      fields = [
        _field(
          entry.titleController,
          "Degree Obtained / Field of Study",
          hint: "e.g., Master of Science in Computer Science",
        ),
        _field(
          entry.detailController,
          "University Name & Location",
          hint: "e.g., MIT, Cambridge, MA",
        ),
        _field(
          entry.extraController1,
          "Graduation Year / Grades / Honors",
          hint:
              "e.g., Grad Year: 2020 | GPA: 3.8 | Dean's List, Relevant Coursework",
        ),
      ];
    } else {
      fields = [
        _field(
          entry.titleController,
          type == 'project' ? "Project Name" : "Role/Organization",
          hint: type == 'project'
              ? "e.g., E-commerce App"
              : "e.g., Lead Volunteer, Red Cross",
        ),
        _field(
          entry.detailController,
          type == 'project'
              ? "Description & Tech Stack"
              : "Responsibilities & Duration",
          lines: 3,
        ),
      ];
    }

    return Card(
      key: entry.key,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (list.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _removeEntry(list, entry),
                    tooltip: 'Remove entry',
                  ),
              ],
            ),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSection({
    required String title,
    required List<DynamicEntry> list,
    required VoidCallback onAdd,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: onAdd,
                tooltip: 'Add new entry',
              ),
            ],
          ),
        ),
        const Divider(height: 5),
        ...list
            .map((entry) => _buildDynamicEntryCard(list, entry, type))
            .toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVisaIdField() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Visa Details (Gulf/International Candidates)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: visaIdController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: "Visa/Residence ID (Optional)",
              hintText: "Enter your Visa ID, Civil ID, or Iqama number",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(
                Icons.credit_card_sharp,
                color: Colors.blue,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 6. MAIN BUILD METHOD
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Job Profile")),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- Resume Upload Button ---
                    ElevatedButton.icon(
                      onPressed: isExtracting ? null : pickResume,
                      icon: const Icon(Icons.file_upload),
                      label: Text(
                        isExtracting
                            ? "Extracting Data..."
                            : "Upload Resume to Auto-Fill",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                    if (isExtracting) const LinearProgressIndicator(),
                    if (selectedResume != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Text(
                          "Selected File: ${selectedResume!.path.split('/').last}",
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),

                    const Divider(height: 20),
                    // --- Contact Information & Headline ---
                    _buildSectionHeader("Contact & Headline "),
                    _field(nameController, "Full Name (First & Last)"),
                    _field(
                      locationController,
                      "Location (City, State)",
                      hint: "e.g., Dallas, TX",
                    ),
                    _field(
                      emailController,
                      "Professional Email",
                      type: TextInputType.emailAddress,
                    ),
                    _field(
                      phoneController,
                      "Contact Number with Area Code",
                      type: TextInputType.phone,
                    ),
                    _field(linkedInController, "LinkedIn URL"),
                    _field(
                      portfolioController,
                      "Professional Website/Portfolio URL",
                    ),
                    _field(
                      headlineController,
                      "Resume Headline (e.g., Civil Engineer with 11+ Years...)",
                      lines: 2,
                    ),
                    _field(
                      summaryController,
                      "Professional Summary/Objective",
                      lines: 4,
                    ),

                    // --- Skills ---
                    _buildSectionHeader("Skills "),
                    _field(
                      skillsController,
                      "Hard, Technical, and Soft Skills (Comma Separated)",
                      lines: 3,
                    ),

                    // --- Dynamic Fields ---
                    _buildDynamicSection(
                      title: "Professional Experience ",
                      list: workExperienceList,
                      onAdd: () => _addEntry(workExperienceList),
                      type: 'work',
                    ),
                    _buildDynamicSection(
                      title: "Education & Certifications 🎓",
                      list: educationList,
                      onAdd: () => _addEntry(educationList),
                      type: 'education',
                    ),
                    _buildDynamicSection(
                      title: "Projects 💻",
                      list: projectsList,
                      onAdd: () => _addEntry(projectsList),
                      type: 'project',
                    ),
                    _buildDynamicSection(
                      title: "Volunteer Experience ",
                      list: volunteerList,
                      onAdd: () => _addEntry(volunteerList),
                      type: 'volunteer',
                    ),

                    // --- Visa ID Field ---
                    _buildVisaIdField(),

                    const SizedBox(height: 20),

                    // --- Save Button ---
                    ElevatedButton(
                      onPressed: isSaving ? null : saveProfile,
                      child: Text(isSaving ? "Saving..." : "Save Profile"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
