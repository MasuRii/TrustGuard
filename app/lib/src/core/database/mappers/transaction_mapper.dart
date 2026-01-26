import 'package:drift/drift.dart';
import '../database.dart';
import 'tag_mapper.dart';
import '../../models/transaction.dart' as model;
import '../../models/expense.dart' as model;
import '../../models/transfer.dart' as model;

class TransactionMapper {
  static model.Transaction toModel({
    required Transaction transaction,
    ExpenseDetail? expenseDetail,
    List<ExpenseParticipant>? participants,
    TransferDetail? transferDetail,
    List<Tag>? tags,
  }) {
    return model.Transaction(
      id: transaction.id,
      groupId: transaction.groupId,
      type: transaction.type,
      occurredAt: transaction.occurredAt,
      note: transaction.note,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      deletedAt: transaction.deletedAt,
      isRecurring: transaction.isRecurring,
      expenseDetail: expenseDetail != null
          ? model.ExpenseDetail(
              payerMemberId: expenseDetail.payerMemberId,
              totalAmountMinor: expenseDetail.totalAmountMinor,
              splitType: expenseDetail.splitType,
              splitMetaJson: expenseDetail.splitMetaJson,
              participants:
                  participants
                      ?.map(
                        (p) => model.ExpenseParticipant(
                          memberId: p.memberId,
                          owedAmountMinor: p.owedAmountMinor,
                        ),
                      )
                      .toList() ??
                  [],
            )
          : null,
      transferDetail: transferDetail != null
          ? model.TransferDetail(
              fromMemberId: transferDetail.fromMemberId,
              toMemberId: transferDetail.toMemberId,
              amountMinor: transferDetail.amountMinor,
            )
          : null,
      tags: tags?.map(TagMapper.toModel).toList() ?? [],
    );
  }

  static TransactionsCompanion toTransactionCompanion(
    model.Transaction domain,
  ) {
    return TransactionsCompanion(
      id: Value(domain.id),
      groupId: Value(domain.groupId),
      type: Value(domain.type),
      occurredAt: Value(domain.occurredAt),
      note: Value(domain.note),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
      deletedAt: Value(domain.deletedAt),
      isRecurring: Value(domain.isRecurring),
    );
  }

  static ExpenseDetailsCompanion? toExpenseDetailCompanion(
    model.Transaction domain,
  ) {
    final detail = domain.expenseDetail;
    if (detail == null) return null;
    return ExpenseDetailsCompanion(
      txId: Value(domain.id),
      payerMemberId: Value(detail.payerMemberId),
      totalAmountMinor: Value(detail.totalAmountMinor),
      splitType: Value(detail.splitType),
      splitMetaJson: Value(detail.splitMetaJson),
    );
  }

  static List<ExpenseParticipantsCompanion> toExpenseParticipantsCompanions(
    model.Transaction domain,
  ) {
    final detail = domain.expenseDetail;
    if (detail == null) return [];
    return detail.participants
        .map(
          (p) => ExpenseParticipantsCompanion(
            txId: Value(domain.id),
            memberId: Value(p.memberId),
            owedAmountMinor: Value(p.owedAmountMinor),
          ),
        )
        .toList();
  }

  static TransferDetailsCompanion? toTransferDetailCompanion(
    model.Transaction domain,
  ) {
    final detail = domain.transferDetail;
    if (detail == null) return null;
    return TransferDetailsCompanion(
      txId: Value(domain.id),
      fromMemberId: Value(detail.fromMemberId),
      toMemberId: Value(detail.toMemberId),
      amountMinor: Value(detail.amountMinor),
    );
  }

  static List<TransactionTagsCompanion> toTransactionTagsCompanions(
    model.Transaction domain,
  ) {
    return domain.tags
        .map(
          (t) => TransactionTagsCompanion(
            txId: Value(domain.id),
            tagId: Value(t.id),
          ),
        )
        .toList();
  }
}
