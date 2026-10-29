import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/models/models.dart';

class PdfResumeGenerator {
  /// Strips or parses markdown bold tokens (**text**) into segments
  static List<_TextSegment> _parseMarkdown(String input) {
    final List<_TextSegment> segments = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(input)) {
      if (match.start > lastIndex) {
        segments.add(_TextSegment(input.substring(lastIndex, match.start), false));
      }
      segments.add(_TextSegment(match.group(1) ?? '', true));
      lastIndex = match.end;
    }

    if (lastIndex < input.length) {
      segments.add(_TextSegment(input.substring(lastIndex), false));
    }

    if (segments.isEmpty) {
      segments.add(_TextSegment(input, false));
    }
    return segments;
  }

  /// Escapes PDF string literal characters
  static String _escapePdf(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)')
        .replaceAll(RegExp(r'[^\x20-\x7E\r\n\t]'), ' ');
  }

  /// Converts markdown text into wrapped lines of tokens
  static List<List<_TextToken>> _wrapMarkdownText(String input, int maxCharsPerLine) {
    final segments = _parseMarkdown(input);
    final List<_TextToken> allTokens = [];

    for (final seg in segments) {
      final words = seg.text.split(RegExp(r'\s+'));
      for (final w in words) {
        if (w.isNotEmpty) {
          allTokens.add(_TextToken(w, seg.isBold));
        }
      }
    }

    if (allTokens.isEmpty) return [];

    final List<List<_TextToken>> lines = [];
    List<_TextToken> currentLine = [];
    int currentLineLength = 0;

    for (final token in allTokens) {
      final tokenLen = token.text.length + 1;
      if (currentLine.isEmpty) {
        currentLine.add(token);
        currentLineLength = token.text.length;
      } else if (currentLineLength + tokenLen <= maxCharsPerLine) {
        currentLine.add(token);
        currentLineLength += tokenLen;
      } else {
        lines.add(List.from(currentLine));
        currentLine = [token];
        currentLineLength = token.text.length;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  /// Wraps a single plain text string into multiple lines
  static List<String> _wrapText(String text, int maxChars) {
    if (text.length <= maxChars) return [text];
    final words = text.split(' ');
    final List<String> lines = [];
    String current = '';

    for (final w in words) {
      if (current.isEmpty) {
        current = w;
      } else if (current.length + 1 + w.length <= maxChars) {
        current += ' $w';
      } else {
        lines.add(current);
        current = w;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  /// Generates a professional multi-page PDF document containing ALL resume fields
  static Future<File> generatePdf(ResumeModel resume) async {
    final List<StringBuffer> pageStreams = [StringBuffer()];
    int currentPage = 0;
    double y = 800;

    // Helper: gets current page stream
    StringBuffer cur() => pageStreams[currentPage];

    // Helper: draws header on Page 1
    void initPage1Header() {
      final s = cur();
      // FlowHire Blue banner (y: 705 to 842)
      s.writeln('0.117 0.458 0.910 rg');
      s.writeln('0 705 595 137 re');
      s.writeln('f');

      // Full Name (White, Bold, 20pt)
      s.writeln('1.0 1.0 1.0 rg');
      s.writeln('BT');
      s.writeln('/F2 20 Tf');
      s.writeln('40 798 Td');
      s.writeln('(${_escapePdf(resume.fullName.isNotEmpty ? resume.fullName.toUpperCase() : "CANDIDATE RESUME")}) Tj');
      s.writeln('ET');

      // Role (White, Bold, 11pt)
      final role = resume.currentRole.isNotEmpty ? resume.currentRole.toUpperCase() : 'CONSTRUCTION PROFESSIONAL';
      s.writeln('BT');
      s.writeln('/F2 11 Tf');
      s.writeln('40 778 Td');
      s.writeln('(${_escapePdf(role)}) Tj');
      s.writeln('ET');

      // Contact Line 1: Phone | Email | Address
      final contact1 = <String>[];
      if (resume.phone.isNotEmpty) contact1.add('Phone: ${resume.phone}');
      if (resume.email.isNotEmpty) contact1.add('Email: ${resume.email}');
      if (resume.currentAddress.isNotEmpty) contact1.add('Location: ${resume.currentAddress}');
      final line1 = contact1.isNotEmpty ? contact1.join('   |   ') : 'FlowHire Verified Professional';

      s.writeln('BT');
      s.writeln('/F1 9 Tf');
      s.writeln('40 756 Td');
      s.writeln('(${_escapePdf(line1)}) Tj');
      s.writeln('ET');

      // Contact Line 2: Date of Birth | Gender | Total Experience
      final contact2 = <String>[];
      if (resume.dob.isNotEmpty) contact2.add('DOB: ${resume.dob}');
      if (resume.gender.isNotEmpty) contact2.add('Gender: ${resume.gender}');
      if (resume.totalExperience.isNotEmpty) contact2.add('Experience: ${resume.totalExperience}');
      final line2 = contact2.join('   |   ');

      if (line2.isNotEmpty) {
        s.writeln('BT');
        s.writeln('/F1 9 Tf');
        s.writeln('40 738 Td');
        s.writeln('(${_escapePdf(line2)}) Tj');
        s.writeln('ET');
      }

      s.writeln('0.06 0.09 0.16 rg');
      y = 680;
    }

    // Helper: initializes top header for Page 2 and beyond
    void initSubsequentPageHeader([String? subtitle]) {
      final s = cur();
      // FlowHire Blue top accent bar (y: 818 to 842)
      s.writeln('0.117 0.458 0.910 rg');
      s.writeln('0 818 595 24 re');
      s.writeln('f');

      // Page header text
      s.writeln('1.0 1.0 1.0 rg');
      s.writeln('BT');
      s.writeln('/F2 9.5 Tf');
      s.writeln('40 825 Td');
      final name = resume.fullName.isNotEmpty ? resume.fullName.toUpperCase() : 'CANDIDATE RESUME';
      final pageSub = subtitle ?? 'Professional Dossier';
      s.writeln('(${_escapePdf("$name   —   $pageSub")}) Tj');
      s.writeln('ET');

      s.writeln('0.06 0.09 0.16 rg');
      y = 785;
    }

    // Start Page 1
    initPage1Header();

    void forceNewPage([String? subtitle]) {
      currentPage++;
      pageStreams.add(StringBuffer());
      initSubsequentPageHeader(subtitle);
    }

    // Helper: checks if content exceeds page boundary; if so, transitions to a new page
    void checkPageOverflow(double neededHeight, [String? nextSubtitle]) {
      if (y - neededHeight < 55) {
        forceNewPage(nextSubtitle);
      }
    }

    // Helper: draws section header
    void drawSectionHeader(String title, [String? nextSubtitle]) {
      checkPageOverflow(80, nextSubtitle);
      final s = cur();

      // Section title
      s.writeln('0.117 0.458 0.910 rg');
      s.writeln('BT');
      s.writeln('/F2 12 Tf');
      s.writeln('40 $y Td');
      s.writeln('(${_escapePdf(title.toUpperCase())}) Tj');
      s.writeln('ET');

      // Underline accent
      s.writeln('40 ${y - 4} 515 1.5 re');
      s.writeln('f');

      s.writeln('0.06 0.09 0.16 rg');
      y -= 22;
    }

    // Helper: draws plain text
    void drawPlainText(String text, {bool isBold = false, double fontSize = 10, double indent = 40}) {
      final lines = _wrapText(text, isBold ? 72 : 86);
      final font = isBold ? '/F2' : '/F1';
      for (final l in lines) {
        checkPageOverflow(fontSize + 4);
        final s = cur();
        s.writeln('BT');
        s.writeln('$font $fontSize Tf');
        s.writeln('$indent $y Td');
        s.writeln('(${_escapePdf(l)}) Tj');
        s.writeln('ET');
        y -= (fontSize + 4);
      }
    }

    // Helper: draws markdown text with bold words
    void drawMarkdownBlock(String text, {double fontSize = 9.5, double indent = 40}) {
      final lines = _wrapMarkdownText(text, 84);
      for (final line in lines) {
        checkPageOverflow(fontSize + 4);
        final s = cur();
        s.writeln('BT');
        s.writeln('$indent $y Td');
        for (int i = 0; i < line.length; i++) {
          final token = line[i];
          final font = token.isBold ? '/F2' : '/F1';
          final spacing = i < line.length - 1 ? ' ' : '';
          s.writeln('$font $fontSize Tf');
          s.writeln('(${_escapePdf(token.text + spacing)}) Tj');
        }
        s.writeln('ET');
        y -= (fontSize + 4);
      }
    }

    // ─── 1. PROFESSIONAL SUMMARY ──────────────────────────
    if (resume.aboutYou.isNotEmpty || resume.totalExperience.isNotEmpty) {
      drawSectionHeader('Professional Summary');
      if (resume.totalExperience.isNotEmpty) {
        drawPlainText('Total Experience: ${resume.totalExperience}', isBold: true, fontSize: 10);
        y -= 2;
      }
      if (resume.aboutYou.isNotEmpty) {
        drawMarkdownBlock(resume.aboutYou, fontSize: 9.5);
      }
      y -= 10;
    }

    // ─── 2. WORK EXPERIENCE (Dedicated page flow for real candidate jobs) ──
    if (resume.workExperiences.isNotEmpty) {
      if (y < 380) {
        forceNewPage('Work Experience');
      }
      drawSectionHeader('Work Experience', 'Work Experience (Continued)');
      for (final exp in resume.workExperiences) {
        final title = exp.jobTitle.isNotEmpty ? exp.jobTitle : 'Role';
        final company = exp.companyName.isNotEmpty ? exp.companyName : '';
        final start = exp.startDate.isNotEmpty ? exp.startDate : '';
        final end = exp.isCurrentlyWorking ? 'Present' : (exp.endDate.isNotEmpty ? exp.endDate : '');
        final dateSpan = start.isNotEmpty ? (end.isNotEmpty ? '($start - $end)' : '($start)') : (end.isNotEmpty ? '($end)' : '');
        final header = company.isNotEmpty ? '$title  at  $company $dateSpan'.trim() : '$title $dateSpan'.trim();

        checkPageOverflow(32, 'Work Experience (Continued)');
        drawPlainText(header, isBold: true, fontSize: 10.5);

        if (exp.responsibility.isNotEmpty) {
          final respLines = exp.responsibility.split(RegExp(r'\n+'));
          for (final rl in respLines) {
            final clean = rl.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
            if (clean.isNotEmpty) {
              drawPlainText('• $clean', indent: 52, fontSize: 9.5);
            }
          }
        }
        y -= 8;
      }
      y -= 8;
    }

    // ─── 3. EDUCATION & TECHNICAL SKILLS ───────────────────
    final hasEducation = resume.educations.isNotEmpty;
    final hasSkills = resume.technicalSkills.isNotEmpty || resume.equipmentOperated.isNotEmpty;

    if ((hasEducation || hasSkills) && y < 320) {
      forceNewPage('Education & Technical Skills');
    }

    // 3. EDUCATION
    if (hasEducation) {
      drawSectionHeader('Education & Qualifications', 'Education & Qualifications');
      for (final edu in resume.educations) {
        final qual = edu.qualification.isNotEmpty ? edu.qualification : 'Degree / Diploma';
        final inst = edu.instituteName.isNotEmpty ? '  —  ${edu.instituteName}' : '';
        checkPageOverflow(28, 'Education & Qualifications');
        drawPlainText('• $qual$inst', isBold: true, fontSize: 10);

        final details = <String>[];
        if (edu.yearOfPassing.isNotEmpty) details.add('Year: ${edu.yearOfPassing}');
        if (edu.percentageOrCgpa.isNotEmpty) details.add('Score / CGPA: ${edu.percentageOrCgpa}');
        if (details.isNotEmpty) {
          drawPlainText(details.join('   |   '), indent: 52, fontSize: 9.5);
        }
        y -= 4;
      }
      y -= 8;
    }

    // 4. SKILLS & MACHINERY
    if (hasSkills) {
      drawSectionHeader('Technical Skills & Machinery', 'Skills & Machinery');
      if (resume.technicalSkills.isNotEmpty) {
        drawPlainText('Trade Skills & Competencies:', isBold: true, fontSize: 10);
        drawPlainText(resume.technicalSkills.join('   •   '), indent: 52, fontSize: 9.5);
        y -= 6;
      }
      if (resume.equipmentOperated.isNotEmpty) {
        drawPlainText('Equipment & Machinery Operated:', isBold: true, fontSize: 10);
        drawPlainText(resume.equipmentOperated.join('   •   '), indent: 52, fontSize: 9.5);
        y -= 6;
      }
      y -= 8;
    }

    // 5. CERTIFICATIONS & LICENSES
    if (resume.certifications.isNotEmpty) {
      drawSectionHeader('Certifications & Professional Licenses', 'Certifications & Licenses');
      for (final cert in resume.certifications) {
        final name = cert.name;
        final issued = cert.issuedBy.isNotEmpty ? '  —  Issued by: ${cert.issuedBy}' : '';
        final date = cert.issueDate.isNotEmpty ? ' (${cert.issueDate})' : '';
        checkPageOverflow(20, 'Certifications & Licenses');
        drawPlainText('• $name$issued$date', isBold: true, fontSize: 9.5);
        y -= 3;
      }
      y -= 8;
    }

    // ─── Footers on All Pages ──────────────────────────────
    final totalPages = pageStreams.length;
    for (int p = 0; p < totalPages; p++) {
      final s = pageStreams[p];
      s.writeln('0.45 0.5 0.6 rg');
      s.writeln('BT');
      s.writeln('/F1 8 Tf');
      s.writeln('40 22 Td');
      s.writeln('(FlowHire Construction Workforce Platform   •   Verified Candidate Dossier   •   Page ${p + 1} of $totalPages) Tj');
      s.writeln('ET');
    }

    // ─── Assemble ISO PDF 1.4 Document ────────────────────
    final List<int> pdfBytes = [];
    final offsets = <int>[];

    void writeString(String str) => pdfBytes.addAll(utf8.encode(str));

    writeString('%PDF-1.4\n');
    writeString('%\xE2\xE3\xCF\xD3\n');

    // Object 1: Catalog
    offsets.add(pdfBytes.length);
    writeString('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Object 2: Pages
    final kids = List.generate(totalPages, (i) => '${5 + 2 * i} 0 R').join(' ');
    offsets.add(pdfBytes.length);
    writeString('2 0 obj\n<< /Type /Pages /Kids [ $kids ] /Count $totalPages >>\nendobj\n');

    // Object 3: Font F1 (Helvetica)
    offsets.add(pdfBytes.length);
    writeString('3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n');

    // Object 4: Font F2 (Helvetica-Bold)
    offsets.add(pdfBytes.length);
    writeString('4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n');

    // Page Objects and Content Stream Objects
    for (int i = 0; i < totalPages; i++) {
      final pageObjId = 5 + 2 * i;
      final contentObjId = pageObjId + 1;
      final streamText = pageStreams[i].toString();
      final streamBytes = utf8.encode(streamText);

      // Page Object
      offsets.add(pdfBytes.length);
      writeString(
        '$pageObjId 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents $contentObjId 0 R >>\nendobj\n',
      );

      // Content Stream Object
      offsets.add(pdfBytes.length);
      writeString('$contentObjId 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
      pdfBytes.addAll(streamBytes);
      writeString('\nendstream\nendobj\n');
    }

    // XREF Table
    final totalObjects = 4 + 2 * totalPages;
    final xrefOffset = pdfBytes.length;
    writeString('xref\n0 ${totalObjects + 1}\n');
    writeString('0000000000 65535 f \n');
    for (final off in offsets) {
      writeString('${off.toString().padLeft(10, '0')} 00000 n \n');
    }

    // Trailer
    writeString('trailer\n<< /Size ${totalObjects + 1} /Root 1 0 R >>\n');
    writeString('startxref\n$xrefOffset\n%%EOF\n');

    final tempDir = await getTemporaryDirectory();
    final safeName = resume.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${tempDir.path}/$safeName.pdf');
    return await file.writeAsBytes(pdfBytes, flush: true);
  }
}

class _TextToken {
  final String text;
  final bool isBold;
  const _TextToken(this.text, this.isBold);
}

class _TextSegment {
  final String text;
  final bool isBold;
  const _TextSegment(this.text, this.isBold);
}
