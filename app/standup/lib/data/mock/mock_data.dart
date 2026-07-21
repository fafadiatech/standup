import '../models/user_model.dart';
import '../models/meeting_model.dart';
import '../models/event_model.dart';
import '../models/achievement_model.dart';
import '../models/holiday_model.dart';
import '../models/task_model.dart';
import '../models/checklist_item_model.dart';
import '../models/attachment_model.dart';
import '../models/comment_model.dart';
import '../models/time_log_model.dart';
import '../models/leave_model.dart';
import '../models/leaderboard_model.dart';
import '../models/notification_model.dart';
import 'package:flutter/material.dart';

class MockData {
  MockData._();

  static const UserModel currentUser = UserModel(
    id: '1',
    name: 'Sarah Connor',
    email: 'sarah@company.com',
    avatarInitials: 'SC',
    leaveBalance: 20,
    energyPoints: 200,
    issueNumber: '#123',
    issueName: 'Internal mobile app design',
    issueStatus: 'on going',
    role: 'UI/UX Designer',
    department: 'Product & Design',
    phone: '+91 98765 43210',
    location: 'Pune, India',
    joinedDate: 'Mar 2022',
    managedBy: 'Raj Mehta',
    employeeId: 'EMP-0042',
  );

  static const List<AchievementModel> achievements = [
    AchievementModel(
      id: '1',
      badgeEmoji: '🎉',
      badgeTitle: 'Early puncher',
      description:
          'Consistently clocking in before 9 AM for the past month. Keep up the great habit!',
      personName: 'Sarah Connor',
      personInitials: 'SC',
      achievedDate: 'Dec 15, 2024',
    ),
    AchievementModel(
      id: '2',
      badgeEmoji: '🏆',
      badgeTitle: 'Team Player',
      description:
          'Went above and beyond to support teammates during the product launch sprint.',
      personName: 'Sarah Connor',
      personInitials: 'SC',
      achievedDate: 'Dec 10, 2024',
    ),
    AchievementModel(
      id: '3',
      badgeEmoji: '⭐',
      badgeTitle: 'Star Contributor',
      description:
          'Contributed 5 successful pull requests reviewed and merged in a single week.',
      personName: 'Sarah Connor',
      personInitials: 'SC',
      achievedDate: 'Nov 28, 2024',
    ),
  ];

  static const List<HolidayModel> upcomingHolidays = [
    HolidayModel(
      id: '1',
      name: 'Christmas holidays',
      date: 'Dec 25 - Jan 1',
    ),
    HolidayModel(
      id: '2',
      name: "New Year's Day",
      date: 'Jan 1, 2025',
    ),
  ];

  static const List<MeetingModel> weeklyMeetings = [
    MeetingModel(
      id: '1',
      teamName: 'Marketing team',
      recurrence: 'Every Tuesday',
      time: '09:00 AM',
    ),
    MeetingModel(
      id: '2',
      teamName: 'UX team meet',
      recurrence: 'Every Tuesday',
      time: '10:00 AM',
    ),
    MeetingModel(
      id: '3',
      teamName: 'XC team meet',
      recurrence: 'Mon & Thu',
      time: '10:00 AM',
    ),
  ];

  static const List<EventModel> upcomingEvents = [
    EventModel(
      id: '1',
      title: 'Rubber Duck',
      date: 'Dec 20, 2024',
      description: 'Annual team debugging session and knowledge sharing workshop.',
    ),
    EventModel(
      id: '2',
      title: 'Team Dinner',
      date: 'Dec 22, 2024',
      description:
          'Year-end celebration dinner at The Grand Restaurant. All team members welcome.',
    ),
    EventModel(
      id: '3',
      title: 'Turf',
      date: 'Dec 28, 2024',
      description: 'Friendly football match at the local turf ground. Come and play!',
    ),
  ];

  // --- Leave ---
  static const LeaveSummary leaveSummary = LeaveSummary(
    total: 12,
    paid: 2,
    unpaid: 0,
    pending: 10,
  );

  static final List<LeaveRecord> leaveHistory = [
    LeaveRecord(
      id: 'lv-1',
      title: 'Not Feeling well today',
      type: LeaveType.paid,
      status: LeaveStatus.pending,
      startDate: DateTime(2024, 11, 23),
      endDate: DateTime(2024, 11, 23),
      reason: 'Fever and cold, need rest.',
    ),
    LeaveRecord(
      id: 'lv-2',
      title: 'Family Function',
      type: LeaveType.paid,
      status: LeaveStatus.rejected,
      startDate: DateTime(2024, 7, 12),
      endDate: DateTime(2024, 7, 13),
      reason: 'Attending a family wedding ceremony.',
    ),
    LeaveRecord(
      id: 'lv-3',
      title: 'Sick Leave',
      type: LeaveType.unpaid,
      status: LeaveStatus.approved,
      startDate: DateTime(2024, 4, 4),
      endDate: DateTime(2024, 4, 5),
      reason: 'Medical procedure follow-up.',
    ),
    LeaveRecord(
      id: 'lv-4',
      title: 'Sick Leave',
      type: LeaveType.unpaid,
      status: LeaveStatus.approved,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 1),
      reason: 'New Year recovery.',
    ),
    LeaveRecord(
      id: 'lv-5',
      title: 'Casual Leave',
      type: LeaveType.casual,
      status: LeaveStatus.approved,
      startDate: DateTime(2023, 10, 20),
      endDate: DateTime(2023, 10, 21),
      reason: 'Personal errands.',
    ),
  ];

  // --- Notifications ---
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n-1',
      type: NotificationType.task,
      title: 'New task assigned',
      body: 'You have been assigned "Update invoice template for Acme Corp".',
      createdAt: DateTime(2026, 7, 17, 9, 15),
      isRead: false,
    ),
    NotificationModel(
      id: 'n-2',
      type: NotificationType.leave,
      title: 'Leave approved',
      body: 'Your sick leave request for Apr 04 has been approved.',
      createdAt: DateTime(2026, 7, 17, 8, 45),
      isRead: false,
    ),
    NotificationModel(
      id: 'n-3',
      type: NotificationType.achievement,
      title: 'New achievement unlocked',
      body: 'You earned the "Early Puncher" badge. Keep it up!',
      createdAt: DateTime(2026, 7, 17, 8, 0),
      isRead: false,
    ),
    NotificationModel(
      id: 'n-4',
      type: NotificationType.meeting,
      title: 'Meeting reminder',
      body: 'UX team meet starts in 15 minutes at 10:00 AM.',
      createdAt: DateTime(2026, 7, 16, 9, 45),
      isRead: true,
    ),
    NotificationModel(
      id: 'n-5',
      type: NotificationType.task,
      title: 'Task overdue',
      body: '"Fix production bug in payroll calculation" is now overdue.',
      createdAt: DateTime(2026, 7, 16, 8, 0),
      isRead: true,
    ),
    NotificationModel(
      id: 'n-6',
      type: NotificationType.leave,
      title: 'Leave rejected',
      body: 'Your paid leave request for Jul 12–13 has been rejected.',
      createdAt: DateTime(2026, 7, 15, 17, 30),
      isRead: true,
    ),
    NotificationModel(
      id: 'n-7',
      type: NotificationType.system,
      title: 'App updated',
      body: 'Standup v1.1.0 is now live with new features and bug fixes.',
      createdAt: DateTime(2026, 7, 15, 10, 0),
      isRead: true,
    ),
  ];

  // --- Leaderboard ---
  static const EmployeeOfMonth employeeOfMonth = EmployeeOfMonth(
    name: 'Semina Gurung',
    role: 'UI/UX Designer',
    description:
        'Semina gurung has been performing outstanding and has finished xconnect project and got employee of this month',
    initials: 'SG',
    avatarColor: Color(0xFF7C3AED),
    displayDate: '24/03/2024',
  );

  static const List<LeaderboardEntry> leaderboard = [
    LeaderboardEntry(
      id: 'lb-1',
      rank: 1,
      name: 'Semina Gurung',
      role: 'UI/UX Designer',
      energyPoints: 1723,
      initials: 'SG',
      avatarColor: Color(0xFF7C3AED),
    ),
    LeaderboardEntry(
      id: 'lb-2',
      rank: 2,
      name: 'Prasad Bhogle',
      role: 'Project Manager',
      energyPoints: 1500,
      initials: 'PB',
      avatarColor: Color(0xFF16A34A),
    ),
    LeaderboardEntry(
      id: 'lb-3',
      rank: 3,
      name: 'Chirag Oza',
      role: 'Fullstack Developer',
      energyPoints: 1300,
      initials: 'CO',
      avatarColor: Color(0xFF1E40AF),
    ),
    LeaderboardEntry(
      id: 'lb-4',
      rank: 4,
      name: 'Shilpa Gaikwad',
      role: 'UI/UX Designer',
      energyPoints: 1000,
      initials: 'SG',
      avatarColor: Color(0xFFDC2626),
    ),
    LeaderboardEntry(
      id: 'lb-5',
      rank: 4,
      name: 'Avantika Dhanawade',
      role: 'Fullstack Developer',
      energyPoints: 960,
      initials: 'AD',
      avatarColor: Color(0xFF0891B2),
    ),
  ];

  // --- Tasks ---
  static final List<TaskModel> tasks = [
    // 1. Overdue – yesterday, high priority, 2 checklist, 1 attachment, 2 comments, 1 time log
    TaskModel(
      id: 'task-1',
      title: 'Update invoice template for Acme Corp',
      description:
          'Revise the standard invoice template to include the new tax fields and branding changes requested by Acme Corp.',
      priority: TaskPriority.high,
      status: TaskStatus.overdue,
      dueDate: DateTime(2026, 7, 16),
      relatedDocument: 'Customer: Acme Corp',
      checklist: [
        ChecklistItem(id: 'cl-1-1', label: 'Update header logo', isCompleted: true),
        ChecklistItem(id: 'cl-1-2', label: 'Add GST field to line items', isCompleted: false),
      ],
      attachments: [
        AttachmentModel(
          id: 'att-1-1',
          fileName: 'invoice_template_v2.pdf',
          fileType: 'pdf',
          fileSize: '245 KB',
        ),
      ],
      comments: [
        CommentModel(
          id: 'cmt-1-1',
          author: 'Raj Mehta',
          text: 'Please make sure the tax calculation matches the new rate.',
          createdAt: DateTime(2026, 7, 15, 9, 30),
        ),
        CommentModel(
          id: 'cmt-1-2',
          author: 'Sarah Connor',
          text: 'Working on it. Should be done by end of day.',
          createdAt: DateTime(2026, 7, 15, 11, 0),
        ),
      ],
      timeLogs: [
        TimeLogModel(
          id: 'tl-1-1',
          date: DateTime(2026, 7, 15),
          startTime: DateTime(2026, 7, 15, 10, 0),
          endTime: DateTime(2026, 7, 15, 11, 30),
          hours: 1.5,
          notes: 'Initial review and header changes',
          synced: true,
        ),
      ],
      hasPendingApproval: false,
      hasActiveTimer: false,
      isSynced: true,
    ),
    // 2. Overdue – 3 days ago, urgent priority
    TaskModel(
      id: 'task-2',
      title: 'Fix production bug in payroll calculation',
      description:
          'Critical bug causing incorrect deductions for employees on the night shift differential pay structure.',
      priority: TaskPriority.urgent,
      status: TaskStatus.overdue,
      dueDate: DateTime(2026, 7, 14),
      relatedDocument: 'Issue: #HR-4821',
      checklist: [],
      attachments: [],
      comments: [],
      timeLogs: [],
      hasPendingApproval: false,
      hasActiveTimer: false,
      isSynced: false,
    ),
    // 3. Today – inProgress, medium, hasActiveTimer, 3 checklist items
    TaskModel(
      id: 'task-3',
      title: 'Design new onboarding flow mockups',
      description:
          'Create high-fidelity Figma mockups for the revised employee onboarding flow including the new e-signature step.',
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
      dueDate: DateTime(2026, 7, 17),
      relatedDocument: 'Project: Mobile App Redesign',
      checklist: [
        ChecklistItem(id: 'cl-3-1', label: 'Wireframes for welcome screen', isCompleted: true),
        ChecklistItem(id: 'cl-3-2', label: 'Figma prototype for step 2-4', isCompleted: true),
        ChecklistItem(id: 'cl-3-3', label: 'Review with UX lead', isCompleted: false),
      ],
      attachments: [],
      comments: [],
      timeLogs: [],
      hasPendingApproval: false,
      hasActiveTimer: true,
      isSynced: true,
    ),
    // 4. Today – todo, high, hasPendingApproval
    TaskModel(
      id: 'task-4',
      title: 'Submit Q2 expense report for approval',
      description:
          'Compile all Q2 receipts and submit the expense report through the finance portal for manager approval.',
      priority: TaskPriority.high,
      status: TaskStatus.todo,
      dueDate: DateTime(2026, 7, 17),
      relatedDocument: 'Finance: Expense Claims',
      checklist: [],
      attachments: [
        AttachmentModel(
          id: 'att-4-1',
          fileName: 'q2_receipts.zip',
          fileType: 'doc',
          fileSize: '3.2 MB',
        ),
        AttachmentModel(
          id: 'att-4-2',
          fileName: 'expense_report_q2.xlsx',
          fileType: 'doc',
          fileSize: '88 KB',
        ),
      ],
      comments: [],
      timeLogs: [],
      hasPendingApproval: true,
      hasActiveTimer: false,
      isSynced: false,
    ),
    // 5. Upcoming – +3 days, todo, low
    TaskModel(
      id: 'task-5',
      title: 'Prepare team retrospective agenda',
      description:
          'Draft the agenda for the upcoming sprint retrospective. Include metrics review, team wins, and improvement areas.',
      priority: TaskPriority.low,
      status: TaskStatus.todo,
      dueDate: DateTime(2026, 7, 20),
      relatedDocument: 'Team: Engineering',
      checklist: [],
      attachments: [],
      comments: [],
      timeLogs: [],
      hasPendingApproval: false,
      hasActiveTimer: false,
      isSynced: true,
    ),
    // 6. Completed – medium, 1 time log
    TaskModel(
      id: 'task-6',
      title: 'Migrate legacy reports to new dashboard',
      description:
          'Recreate all existing management reports in the new analytics dashboard and verify data accuracy.',
      priority: TaskPriority.medium,
      status: TaskStatus.completed,
      dueDate: DateTime(2026, 7, 10),
      relatedDocument: 'Project: Analytics Platform',
      checklist: [
        ChecklistItem(id: 'cl-6-1', label: 'Migrate revenue summary report', isCompleted: true),
        ChecklistItem(id: 'cl-6-2', label: 'Migrate headcount report', isCompleted: true),
      ],
      attachments: [
        AttachmentModel(
          id: 'att-6-1',
          fileName: 'migration_notes.doc',
          fileType: 'doc',
          fileSize: '52 KB',
        ),
      ],
      comments: [
        CommentModel(
          id: 'cmt-6-1',
          author: 'Priya Sharma',
          text: 'Great work! All reports are verified and accurate.',
          createdAt: DateTime(2026, 7, 10, 16, 0),
        ),
      ],
      timeLogs: [
        TimeLogModel(
          id: 'tl-6-1',
          date: DateTime(2026, 7, 9),
          startTime: DateTime(2026, 7, 9, 9, 0),
          endTime: DateTime(2026, 7, 9, 13, 0),
          hours: 4.0,
          notes: 'Completed revenue and headcount report migration',
          synced: true,
        ),
      ],
      hasPendingApproval: false,
      hasActiveTimer: false,
      isSynced: true,
    ),
  ];
}
