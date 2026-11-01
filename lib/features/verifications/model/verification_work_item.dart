class VerificationWorkItem {
  const VerificationWorkItem({
    required this.expectationId,
    required this.displayName,
    required this.searchStatus,
    this.subjectTicketId,
    this.resultStatus,
  });

  final String expectationId;
  final String displayName;
  final String? subjectTicketId;
  final String searchStatus;
  final String? resultStatus;

  factory VerificationWorkItem.fromJson(Map<String, dynamic> json) =>
      VerificationWorkItem(
        expectationId: json['expectationId'] as String,
        displayName: json['displayName'] as String,
        subjectTicketId: json['subjectTicketId'] as String?,
        searchStatus: json['searchStatus'] as String,
        resultStatus: json['resultStatus'] as String?,
      );
}
