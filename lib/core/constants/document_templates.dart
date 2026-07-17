// lib/core/constants/document_templates.dart

import '../widgets/printable_document_hub.dart';

class DocumentTemplates {
  static List<FormTemplate> getTemplatesForModule(String module) {
    switch (module.toLowerCase()) {
      case 'leave_out':
        return [
          FormTemplate(
            title: 'Leave-Out Slip',
            description: 'Printed/digital slip specifying reason and out block, authorized by Deputy.',
            defaultFields: {
              'Student Name': 'John Doe',
              'Reg Number': '2026/CBC/0149',
              'Class / Grade': 'Grade 7 East',
              'Reason for Leave': 'Medical Appointment (Dental)',
              'Expected Return Date': '19 July 2026',
              'Authorized By': 'Deputy Principal Academics',
            },
          ),
          FormTemplate(
            title: 'Re-entry Confirmation Slip',
            description: 'Countersigned by gate security officer at gate upon return.',
            defaultFields: {
              'Student Name': 'John Doe',
              'Slip Serial': 'LO-2026-081',
              'Actual Return Time': '19 July 2026, 4:30 PM',
              'Physical Check Status': 'Healthy / Normal condition',
              'Security Officer Name': 'Corporal Mwangi',
            },
          ),
          FormTemplate(
            title: 'Serious Case Escalation Note',
            description: 'Auto-generated incident summary for serious misconduct or emergency evacuations.',
            defaultFields: {
              'Subject': 'Unsanctioned Leave-Out Attempt',
              'Student Name': 'John Doe',
              'Incident Details': 'Student attempted to leave campus boundary via West Fence without gate pass.',
              'Urgency Level': 'CRITICAL',
              'Action Required': 'Deputy Principal discipline panel hearing scheduled.',
            },
          ),
        ];

      case 'security':
        return [
          FormTemplate(
            title: 'Vehicle / Person Gate Pass',
            description: 'Official authorization slip recording entry/exit details.',
            defaultFields: {
              'Visitor Name': 'Robert Kamau',
              'Identification ID / Passport': '29481039',
              'Vehicle Reg Number': 'KDD 459X',
              'Purpose of Visit': 'Maintenance of solar panel systems',
              'Host Staff Name': 'Mr. J. Kiprop (Facilities Manager)',
              'Approved Entry Time': '8:30 AM',
            },
          ),
          FormTemplate(
            title: 'Delivery Note Receipt Acknowledgment',
            description: 'Acknowledgment form countersigned by Store Keeper or Cateress.',
            defaultFields: {
              'Supplier Name': 'Eldoret Wholesale Distributors',
              'Delivery Note No': 'DN-98492',
              'Consignment Details': '50 Bags of Long Grain Rice, 20 Jerrycans of cooking oil',
              'Checked By': 'Cateress Millicent',
              'Quality Rating': 'Satisfactory / Sealed',
            },
          ),
          FormTemplate(
            title: 'Visitor Declaration Form',
            description: 'Mandatory registration declaration form for non-parent walk-in visitors.',
            defaultFields: {
              'Visitor Name': 'Alice Muthoni',
              'Contact Email': 'alice.m@gmail.com',
              'Contact Number': '+254711223344',
              'Business Profile': 'TechConsult Ltd',
              'Vehicle Plate No': 'N/A (Pedestrian)',
              'Declaration Statement': 'I declare I have no symptoms of infectious illness and agree to school safety protocols.',
            },
          ),
          FormTemplate(
            title: 'Visiting School MoU / Visit Log Sheet',
            description: 'Standard exchange agreement framework for visiting schools.',
            defaultFields: {
              'Visiting School': 'St. George High School',
              'Activity Coordinator Name': 'Mrs. Jane Njoroge',
              'Number of Delegates': '40 Students, 3 Teachers',
              'Hosted Event': 'District Science Fair Congress',
              'Insurance Hold Harmless Status': 'Signed & Verified',
            },
          ),
          FormTemplate(
            title: 'Incident Report Form',
            description: 'Night shift incident or border breaching escalation track.',
            defaultFields: {
              'Reporting Officer': 'Sgt. J. Omondi (Night Shift Supervisor)',
              'Incident Category': 'Security Fence Breach / Trespass',
              'Detailed Description': 'Detected intruder near Dorm Block C boundary. Suspect fled when security lights activated.',
              'Action Taken': 'Police contacted, patrols doubled around perimeter.',
            },
          ),
          FormTemplate(
            title: 'Camera Access Authorization Slip',
            description: 'Physical or system key issuance track records.',
            defaultFields: {
              'Authorized Staff': 'Mr. Evans Kibet (IT Department)',
              'Access Period Granted': '20 July 2026 to 25 July 2026',
              'Justification': 'Annual system calibration and archive validation',
              'Authorization Level': 'Level 3 Control Room',
            },
          ),
        ];

      case 'store':
        return [
          FormTemplate(
            title: 'Asset Assignment Form',
            description: 'Condition at issue and recipient accountability agreement.',
            defaultFields: {
              'Asset Description': 'Lenovo ThinkPad L14 Gen 2 (Serial: LNV-48291)',
              'Assigned Recipient': 'Teacher Gladys Cherono',
              'Department': 'Senior Primary Sciences',
              'Condition at Issue': 'Brand New / Sealed Box',
              'Agreement Clause': 'I agree to utilize this property strictly for academic instructions.',
            },
          ),
          FormTemplate(
            title: 'Asset Return Form',
            description: 'Verifies asset state at return block.',
            defaultFields: {
              'Asset Tag ID': 'ST-COMP-942',
              'Returning Staff': 'Teacher Gladys Cherono',
              'Condition on Return': 'Operational (Light cosmetic wear on casing)',
              'Received By': 'Store Keeper Peter',
            },
          ),
          FormTemplate(
            title: 'Stock Requisition Form',
            description: 'Internal department material request before placing external LPO orders.',
            defaultFields: {
              'Requisition Code': 'SR-2026-441',
              'Requested Items': '15 Boxes of whiteboard markers (blue), 10 reams of A4 photocopy papers',
              'Requesting Department': 'Examinations Secretariat',
              'Authorizing HOD': 'Dr. S. Lagat',
            },
          ),
          FormTemplate(
            title: 'Procurement Order Form / LPO',
            description: 'Official Local Purchase Order sent to vendors.',
            defaultFields: {
              'LPO Number': 'SWIFT-LPO-1094',
              'Supplier Vendor': 'Apex Stationers Eldoret Ltd',
              'Itemized List': '100 CBC Grade 7 Assessment Booklets @ KSh 450 each',
              'Total Indicated cost': 'KSh 45,000',
              'Delivery Destination': 'Central Store Block A',
            },
          ),
          FormTemplate(
            title: 'Goods Received Note (GRN)',
            description: 'Receiving ledger documenting supplier delivery checklist accuracy.',
            defaultFields: {
              'GRN Number': 'GRN-2026-582',
              'Reference LPO No': 'SWIFT-LPO-1094',
              'Received Quantity': '100 Booklets (100% fulfilled)',
              'Inspection Verdict': 'ACCEPTED',
            },
          ),
        ];

      case 'library':
        return [
          FormTemplate(
            title: 'Library Card / Membership Registration',
            description: 'Library database card registration log.',
            defaultFields: {
              'Member Name': 'Brian Kiplagat',
              'Membership Class': 'Student (Grade 8)',
              'Reg / Patron ID': 'LIB-2026-0048',
              'Daily Issue Limit': '3 books maximum',
              'Default Loan Duration': '14 calendar days',
            },
          ),
          FormTemplate(
            title: 'Book Issue / Return Slip',
            description: 'Borrowing checkout slip indicating loan duration limits.',
            defaultFields: {
              'Borrower Name': 'Brian Kiplagat',
              'Book Title': 'Understanding CBC Mathematics Grade 8',
              'Accession No': 'ACC-98428',
              'Return Deadline': '31 July 2026',
            },
          ),
          FormTemplate(
            title: 'Overdue / Fine Notice',
            description: 'Official warning notice for overdue library publications.',
            defaultFields: {
              'Recipient Patron': 'Brian Kiplagat',
              'Overdue Book': 'Understanding CBC Mathematics Grade 8',
              'Days Overdue': '9 days',
              'Daily Fine Rate': 'KSh 20 per day',
              'Total Fine Owed': 'KSh 180',
            },
          ),
          FormTemplate(
            title: 'New-Title Procurement Request',
            description: 'Feeds into Store Keeper Local Purchase Order pipeline.',
            defaultFields: {
              'Proposed Title': 'Sparsity and Computational Neuroscience Vol II',
              'Author': 'Prof. A. Mbonde',
              'Required Copies': '5',
              'Purpose of Title': 'Senior Junior School Reference Reading',
            },
          ),
        ];

      case 'fleet':
        return [
          FormTemplate(
            title: 'Transport Enrollment & Consent Form',
            description: 'Parent authorization contract detailing specific school shuttle route tariffs.',
            defaultFields: {
              'Student Name': 'Faith Chepngetich',
              'Parent Name': 'Mrs. Sarah Chepngetich',
              'Assigned Route': 'Langas - Elgon View Express Route',
              'Termly Transport Fee': 'KSh 12,000 per term',
              'Emergency Drop point': 'Langas Stage 4 Shop',
            },
          ),
          FormTemplate(
            title: 'Daily Fleet Manifest',
            description: 'Daily commuter checklist for school bus drivers.',
            defaultFields: {
              'Vehicle Plate No': 'KCX 902Y (Bus 1)',
              'Driver Name': 'David Chege',
              'Route Track': 'Eldoret CBD - Kapseret Route',
              'Student Commuter count': '48 Students',
              'Attendant Name': 'Madam Scolastica',
            },
          ),
          FormTemplate(
            title: 'Vehicle Maintenance & Service Log',
            description: 'Detailed regular maintenance tracking sheet.',
            defaultFields: {
              'Vehicle Unit': 'Mini-van KCY 442A',
              'Odometer Reading': '124,591 KM',
              'Service Category': 'Engine oil change, brake pad replacement, alignment',
              'Garage Vendor': 'Kapsoya Elite Auto Garage',
              'Total Cost Invoice': 'KSh 18,500',
            },
          ),
          FormTemplate(
            title: 'Incident & Breakdown Report',
            description: 'Log report for mechanical delays or road occurrences.',
            defaultFields: {
              'Vehicle Code': 'Bus 3 (KDG 812B)',
              'GPS Location': 'Kapkugerwet Junction',
              'Problem Encountered': 'Left rear tire puncture + radiator heating alert',
              'Relief Van Spooled': 'Van 2 dispatched for student evacuation',
            },
          ),
          FormTemplate(
            title: 'Fuel Log Sheet',
            description: 'Tracks fuel usage and fuel efficiency metrics.',
            defaultFields: {
              'Vehicle Unit': 'Bus KCX 902Y',
              'Fuel Litres Added': '85 Litres',
              'Cost Per Litre': 'KSh 182.50',
              'Total Cost': 'KSh 15,512.50',
              'Station Partner': 'Rubis Eldoret Highway',
            },
          ),
        ];

      case 'trips':
        return [
          FormTemplate(
            title: 'Trip Proposal Form',
            description: 'Completed by subject teacher specifying educational objectives.',
            defaultFields: {
              'Proposed Destination': 'Lake Bogoria National Reserve',
              'Subject Core': 'Geography field learning (Geysers & Salinity)',
              'Target Group': 'Grade 9 East & West',
              'Total Student Count': '75 Students',
              'Budget Cost per Student': 'KSh 1,200',
            },
          ),
          FormTemplate(
            title: 'Parent Permission & Payment Slip',
            description: 'Consent circular signed by parents containing indemnity clauses.',
            defaultFields: {
              'Student Name': 'Victor Kiprotich',
              'Activity Name': 'Sub-county Athletics Tournament (Kapsabet)',
              'Trip Date': '26 July 2026',
              'Activity Fee': 'KSh 800 (Paid via M-Pesa STK)',
              'Indemnity Acknowledgment': 'I hereby consent to my child participating in this field trip.',
            },
          ),
          FormTemplate(
            title: 'Headteacher Digital Authorization Form',
            description: 'Approved clearance sheet confirming budget & logistics viability.',
            defaultFields: {
              'Trip Title': 'Academic Seminar: Nairobi National Museum',
              'Lead Coordinator': 'Mr. Philemon Kiprop',
              'Staff-to-Student Ratio': '1:10 (8 teachers, 80 students)',
              'Budget Approval Status': 'APPROVED (Allocated from Board budget)',
            },
          ),
          FormTemplate(
            title: 'Trip Manifest',
            description: 'Official student list handed to drivers and security desks.',
            defaultFields: {
              'Trip Event Name': 'Lake Bogoria Field Trip',
              'Fleet Assigned': 'Bus 1 & Bus 2',
              'Lead Teacher In Charge': 'Mrs. Elizabeth Wambua',
              'Total Headcount Boarded': '80 students, 6 staff',
            },
          ),
        ];

      case 'casual_staff':
        return [
          FormTemplate(
            title: 'Casual Worker Engagement Form',
            description: 'Contract specifying rate, ID check, and engagement period.',
            defaultFields: {
              'Worker Name': 'Jackson Wekesa',
              'National ID Number': '32098412',
              'Daily Rate Contract': 'KSh 900 per day',
              'Task Assignment': 'Perimeter fence brickwork reinforcement',
              'Engagement Period': '15 Days / Fixed-term contractor',
            },
          ),
          FormTemplate(
            title: 'Daily Attendance & Wage Reconciliation Sheet',
            description: 'Daily log used by account/bursar office to calculate pay packets.',
            defaultFields: {
              'Worker Name': 'Jackson Wekesa',
              'Days Worked': '6 days (Week Ending 17 July 2026)',
              'Gross Wage Owed': 'KSh 5,400',
              'Statutory Deductions': 'N/A (Casual Contractor)',
              'Net Payout': 'KSh 5,400',
            },
          ),
          FormTemplate(
            title: 'Casual-to-Permanent Conversion Note',
            description: 'Formal HR proposal to regularize exemplary casual builders or cooks.',
            defaultFields: {
              'Candidate Name': 'Jackson Wekesa',
              'Original Casual Role': 'Lead Mason',
              'Proposed Job Title': 'Resident Caretaker & Facilities Supervisor',
              'Monthly Salary Scale': 'KSh 25,000 basic + allowances',
              'Transition Target Date': '01 August 2026',
            },
          ),
        ];

      case 'reception':
        return [
          FormTemplate(
            title: 'Digital Visitor Log Sheet Backup',
            description: 'General receptionist ledger record.',
            defaultFields: {
              'Date Logged': '17 July 2026',
              'Total Registered entries': '24 Visitors',
              'Peak Entry Hour': '10:00 AM - 11:30 AM',
              'Critical Incidents Noted': 'NONE',
            },
          ),
          FormTemplate(
            title: 'Appointment Request / Confirmation Slip',
            description: 'Booking reservation ticket for parents or external stakeholders.',
            defaultFields: {
              'Stakeholder Name': 'Rev. Fr. Patrick Oduor',
              'Meeting Host': 'Office of the Principal Director',
              'Agreed Date & Time': '23 July 2026, 11:00 AM',
              'Discussion Core': 'Annual Inter-faith Student Assembly Coordination',
            },
          ),
          FormTemplate(
            title: 'Bulk SMS Consent & Template Log',
            description: 'Official file trace copy of SMS broadcasts dispatched.',
            defaultFields: {
              'Target Audience Group': 'All Parent-Guardians of Grade 7',
              'Dispatch Time': '17 July 2026, 6:00 PM',
              'Message Sent': 'Dear parent, please note school closing term day is Friday 31st July.',
              'Total Recipients Count': '182 Contacts',
            },
          ),
          FormTemplate(
            title: 'School Circular / Event Notice',
            description: 'General informational publication issued to stakeholders.',
            defaultFields: {
              'Subject': 'Term 2 Half-Term Academic Appraisal Release',
              'Event Date': '24 July 2026',
              'Key Instructions': 'Parents are invited to pick report booklets from respective class tutors.',
              'Signed Authority': 'Principal Academics Council',
            },
          ),
          FormTemplate(
            title: 'Admission & Offer Letter',
            description: 'Issued on successful student evaluation, referencing fee structures.',
            defaultFields: {
              'Applicant Student': 'Master Shawn Cheruiyot',
              'Parent-Guardian': 'Dr. & Mrs. Cheruiyot',
              'Target Admission Class': 'Grade 7 Intake',
              'Opening Term Date': '01 September 2026',
              'Initial Deposit Required': 'KSh 15,000 (Non-refundable)',
            },
          ),
          FormTemplate(
            title: 'Parent/Guardian Enrollment Contract',
            description: 'Fee liability, code of conduct, and withdrawal policies agreement.',
            defaultFields: {
              'Payer Parent Name': 'Dr. Silas Cheruiyot',
              'Student Ward': 'Shawn Cheruiyot',
              'Withdrawal Clause Notice': 'One full term academic notice period required for fee refunds.',
              'Code of Conduct Acknowledgment': 'Agree to disciplinary manual frameworks.',
            },
          ),
          FormTemplate(
            title: 'Transfer / Leaving Certificate',
            description: 'Official egress document required by successive schools.',
            defaultFields: {
              'Leaving Student': 'Sandra Mwende',
              'Date of Admission': '04 January 2022',
              'Date of Departure': '17 July 2026',
              'Egress Class / Level': 'Grade 9 Completed',
              'Character Conduct Assessment': 'EXCELLENT',
            },
          ),
          FormTemplate(
            title: 'Fee Structure & Payment Guide Letter',
            description: 'Fee invoice template accompanying admissions.',
            defaultFields: {
              'Target Grade': 'Junior School Class (Grades 7-9)',
              'Term Basic Tuition Fee': 'KSh 32,500',
              'Lunch Scheme Option': 'KSh 4,500',
              'Activity Activity Levy': 'KSh 2,000',
              'Official Paybill Number': 'M-Pesa Business: 4022883',
            },
          ),
          FormTemplate(
            title: 'Transport (Fleet) Consent & Fee Addendum',
            description: 'Signed bus transit service policy tracker.',
            defaultFields: {
              'Student Passenger': 'Shawn Cheruiyot',
              'Shuttle Route Zone': 'Zone B (Elgon View - Rift Valley)',
              'Commuter Fee': 'KSh 8,500 per term',
              'Safety Undertaking': 'Agree to keep hands inside window frames during transit.',
            },
          ),
          FormTemplate(
            title: 'Medical Consent & Emergency Contact Form',
            description: 'Allergies, emergency permissions file.',
            defaultFields: {
              'Student Patient': 'Shawn Cheruiyot',
              'Known Allergies': 'Peanuts / Dust Mites',
              'Regular Administered Meds': 'Ventolin Inhaler on active wheeze',
              'Emergency Clinic Contact': 'Dr. J. N. Mwangi, Eldoret Hospital (+254722...)',
              'Approved Clinic Referrals': 'YES (Hospital referral approved)',
            },
          ),
          FormTemplate(
            title: 'Confidentiality & Safeguarding Agreement',
            description: 'Child abuse zero-tolerance signed agreement standard for visiting actors.',
            defaultFields: {
              'Visiting Party / Assessor': 'Prof. Timothy Njoroge (Ministry of Educ.)',
              'Safeguarding Policy Version': 'MoE Act Section 14 (Child Protection Rules)',
              'Declaration Statement': 'I agree to the non-disclosure of student database identifiers.',
            },
          ),
          FormTemplate(
            title: 'Visitor NDA and Waiver',
            description: 'Legal access check for sensitive facilities.',
            defaultFields: {
              'Visitor Accessee': 'Apex Auditing Solutions Ltd',
              'Audited Department': 'Central Bursar Office & Finance Vault',
              'Restricted Information Scope': 'All internal ledger ledgers & bank sheets',
            },
          ),
        ];

      case 'boarding':
        return [
          FormTemplate(
            title: 'Dormitory Allocation Sheet',
            description: 'Official bed assignment record signed and confirmed by Boarding Master.',
            defaultFields: {
              'Student Boarder': 'Andrew Kipchumba',
              'Dormitory Block': 'Simba Dormitory',
              'Assigned Room No': 'Room 12 (Ground Floor)',
              'Bed Slot ID': 'SIM-12B (Lower Bunk)',
              'Luggage Lock Box ID': 'L-4828',
            },
          ),
          FormTemplate(
            title: 'Facility Inspection Report',
            description: 'Detailed inspection check for washrooms, compounds, or dorms.',
            defaultFields: {
              'Inspected Area': 'Simba Washrooms (North Wing)',
              'Hygiene Rating': '9/10 (Excellent/Disinfected)',
              'Maintenance Fault Check': 'Minor leak discovered on Sink Tap 4',
              'Action Urgency Status': 'ROUTINE (Tiler/Plumber action spooled)',
            },
          ),
          FormTemplate(
            title: 'Dining Table Allocation List',
            description: 'Roster matching students to tables and assigning team leaders.',
            defaultFields: {
              'Dining Table No': 'Table 8 (Grade 8 Cluster)',
              'Table Leader Name': 'Student Captain Samuel Limo',
              'Commuter Boarders Count': '12 boarders',
              'Special Dietary Notes': '1 Student (Gluten Free)',
            },
          ),
          FormTemplate(
            title: 'Facility Maintenance Log',
            description: 'Tracks fire extinguishers, safety doors, or lighting fixtures.',
            defaultFields: {
              'Equipment Tag': 'Fire Extinguisher ABC-982',
              'Last Refill Date': '04 April 2026',
              'Next Inspection Target': '04 October 2026',
              'Pressure Gauge Indicator': 'GREEN (Operational)',
            },
          ),
        ];

      case 'hr':
        return [
          FormTemplate(
            title: 'Job Vacancy Advertisement Circular',
            description: 'Vacancy notice drafted for external portals.',
            defaultFields: {
              'Job Opportunity': 'Senior Geography Teacher (Junior School Grade 7-8)',
              'Required Certifications': 'TSC Registered / Bachelor of Education in Geography',
              'Offered Compensation Package': 'KSh 45,000 - 55,000 per month basic line',
              'Application Closing Date': '10 August 2026',
            },
          ),
          FormTemplate(
            title: 'Letter of Offer',
            description: 'Pre-contract specifying core terms and probationary thresholds.',
            defaultFields: {
              'Candidate Offer Name': 'Miss Diana Jebet',
              'Proposed Position': 'General Primary Sciences Teacher',
              'Base Salary Scale': 'KSh 38,000 basic base monthly',
              'Probation Duration': '3 calendar months',
              'Reporting Supervisor': 'Senior Headteacher Academy',
            },
          ),
          FormTemplate(
            title: 'Employment Contract',
            description: 'Permanent/fixed-term official labor contract template.',
            defaultFields: {
              'Employee Name': 'Miss Diana Jebet',
              'Term': '2-Year Renewable Fixed Term',
              'Leave Allowance Details': '21 Days Annual Paid Holiday',
              'Termination Notice Target': '1 calendar month written notice',
            },
          ),
          FormTemplate(
            title: 'Job Description Sheet',
            description: 'Outlines target performance vectors.',
            defaultFields: {
              'Designation Role': 'Class Tutor & Primary Science Instructor',
              'Core Operations Key Areas': 'Deliver CBC science modules, record assessments, join parent appraisal days',
              'Extra-Curricular Assignment': 'Patron: Environment and Gardening Club',
            },
          ),
          FormTemplate(
            title: 'Statutory Compliance Input Form',
            description: 'Documents KRA, SHIF, and NSSF coordinates.',
            defaultFields: {
              'Employee Name': 'Miss Diana Jebet',
              'KRA PIN Identifier': 'A009848201K',
              'NSSF Member ID': 'NSSF-9842881',
              'SHA (SHIF) Health Account': 'SHA-4820109Z',
            },
          ),
          FormTemplate(
            title: 'Leave Application & Approval Slip',
            description: 'Official tracking template for staff absences.',
            defaultFields: {
              'Staff Applicant': 'Mrs. Florence Kiprop',
              'Leave Category Requested': 'Maternity Leave',
              'Duration Period': '90 Days (01 Sept 2026 to 30 Nov 2026)',
              'Alternative Cover Officer': 'Mr. Evans Kibet',
            },
          ),
          FormTemplate(
            title: 'Disciplinary Warning Letter',
            description: 'Structured warning letter for workplace indiscipline.',
            defaultFields: {
              'Staff Recipient': 'Teacher Mark Kiprono',
              'Reason for Warning': 'Repeated late reporting during morning assembly duties',
              'Previous Discussion Date': '04 July 2026 (Verbal warning issued)',
              'Consequence Clause': 'Further late arrivals will trigger formal board actions.',
            },
          ),
          FormTemplate(
            title: 'Teacher Quarter Allocation Form',
            description: 'Housing license agreement for on-site teacher townhouses.',
            defaultFields: {
              'Staff Resident': 'Miss Diana Jebet',
              'Allocated Unit ID': 'Unit QA-05 (2 Bedroom)',
              'Utility Sharing Policy': 'KSh 1,500/month flat-rate electricity charge',
              'Indemnity Bond': 'Tenant agrees to hand over unit in clean state.',
            },
          ),
          FormTemplate(
            title: 'Certificate of Service / Leaving Reference',
            description: 'Official egress document issued to departing school employees.',
            defaultFields: {
              'Former Employee': 'Mr. Paul Nalianya',
              'Service Period': 'January 2020 to July 2026',
              'Last Designation Position': 'Head HOD Sciences Primary',
              'Exit Status': 'Resigned voluntarily with credit',
            },
          ),
        ];

      case 'nurse':
        return [
          FormTemplate(
            title: 'Emergency Medical Consent Form',
            description: 'Information list documenting allergen protocols.',
            defaultFields: {
              'Student Patient': 'Sharon Chematia',
              'Class / Section': 'Grade 8 West',
              'Allergies Declared': 'Bee stings / Penicillin drug family',
              'Emergency Treatment Limit': 'Authorized to administer adrenaline injector if anaphylaxis occurs.',
            },
          ),
          FormTemplate(
            title: 'Medication Administration Record (MAR)',
            description: 'Detailed logs for daily administered medication doses.',
            defaultFields: {
              'Student Patient': 'Sharon Chematia',
              'Drug Name & Strength': 'Ritalin 10mg morning tablet',
              'Administration Time': 'Daily at 8:15 AM',
              'Prescribing Physician': 'Dr. K. Serem (Consultant Psychiatrist)',
            },
          ),
          FormTemplate(
            title: 'Injury and Incident Report',
            description: 'Tracks medical actions for injuries on school grounds.',
            defaultFields: {
              'Student Athlete': 'Ken Kiptoo',
              'Circumstances of Injury': 'Sprained ankle during high-jump athletics practice',
              'Applied First Aid': 'Ice pack compress, limb elevation, elastic compression bandage',
              'Clinic Status': 'Dispatched home with recommendation for 2 days rest',
            },
          ),
          FormTemplate(
            title: 'Clinic Referral Slip',
            description: 'Transfer instructions for outside hospitals.',
            defaultFields: {
              'Referral Destination': 'Reale Hospital Eldoret Outpatient Clinic',
              'Patient Student': 'Ken Kiptoo',
              'Reason for Referral': 'X-Ray imaging to rule out hairline fracture',
              'Accompanying Staff': 'Nurse Gladys',
            },
          ),
          FormTemplate(
            title: 'Immunization & Health Screening Card',
            description: 'Records vaccinations and periodic physical tests.',
            defaultFields: {
              'Student Patient': 'Sharon Chematia',
              'Tetanus Toxoid Booster': 'Administered: 12 January 2026',
              'General Eye Test Result': '6/6 Left Eye, 6/9 Right Eye',
              'Dental Status': 'Healthy / No caries',
            },
          ),
        ];

      case 'catering':
        return [
          FormTemplate(
            title: 'Daily Meal Ingredient Sheet',
            description: 'Inventory draw sheet specifying quantities requested from Store Keeper.',
            defaultFields: {
              'Date': '17 July 2026',
              'Meal Type': 'Lunch',
              'Menu': 'Maize and Beans (Githeri) with shredded cabbage',
              'Servings Count': '450 portions',
              'Requested Ingredients': '90kg Beans, 110kg Maize, 15 Jerrycans Cooking Oil, 40 Cabbages',
              'Cateress Signature': 'Cateress Millicent',
            },
          ),
          FormTemplate(
            title: 'Student Dietary Allergy List',
            description: 'Registry extract showing students with custom dietary requirements.',
            defaultFields: {
              'Active Student Count': '4 Students',
              'Allergy Alerts': 'John Doe (Peanuts), Jane Roe (Gluten/Celiac), Mary Smith (Lactose)',
              'Special Meal Prepared': 'Gluten-free sorghum porridge, dairy-free cabbage alternatives',
            },
          ),
          FormTemplate(
            title: 'Special Board & Banquet Menu Request',
            description: 'Approval request for special banquets, school events, or visiting school lunches.',
            defaultFields: {
              'Event Name': 'Annual Board of Management Meeting',
              'Expected Guests': '15 Board members',
              'Date of Event': '28 July 2026',
              'Proposed Menu': 'Brown wholemeal chapati, roasted beef stew, traditional greens, fresh fruit punch salad',
              'Estimated Extra Budget': 'KSh 12,500',
              'Approved By': 'Principal Director Office',
            },
          ),
        ];

      default:
        return [];
    }
  }
}
