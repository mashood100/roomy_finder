// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_conversation_v2.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatConversationV2Collection on Isar {
  IsarCollection<ChatConversationV2> get chatConversationV2s =>
      this.collection();
}

const ChatConversationV2Schema = CollectionSchema(
  name: r'ChatConversationV2',
  id: 2070078216661054076,
  properties: {
    r'blocks': PropertySchema(
      id: 0,
      name: r'blocks',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'key': PropertySchema(
      id: 2,
      name: r'key',
      type: IsarType.string,
    ),
    r'unReadMessageCount': PropertySchema(
      id: 3,
      name: r'unReadMessageCount',
      type: IsarType.long,
    )
  },
  estimateSize: _chatConversationV2EstimateSize,
  serialize: _chatConversationV2Serialize,
  deserialize: _chatConversationV2Deserialize,
  deserializeProp: _chatConversationV2DeserializeProp,
  idName: r'isarId',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'first': LinkSchema(
      id: 7980779929483783195,
      name: r'first',
      target: r'User',
      single: true,
    ),
    r'second': LinkSchema(
      id: -3159950086091900487,
      name: r'second',
      target: r'User',
      single: true,
    ),
    r'lastMessage': LinkSchema(
      id: -162752873255797274,
      name: r'lastMessage',
      target: r'ChatMessageV2',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _chatConversationV2GetId,
  getLinks: _chatConversationV2GetLinks,
  attach: _chatConversationV2Attach,
  version: '3.1.0+1',
);

int _chatConversationV2EstimateSize(
  ChatConversationV2 object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blocks.length * 3;
  {
    for (var i = 0; i < object.blocks.length; i++) {
      final value = object.blocks[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.key.length * 3;
  return bytesCount;
}

void _chatConversationV2Serialize(
  ChatConversationV2 object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.blocks);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.key);
  writer.writeLong(offsets[3], object.unReadMessageCount);
}

ChatConversationV2 _chatConversationV2Deserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ChatConversationV2(
    blocks: reader.readStringList(offsets[0]) ?? [],
    createdAt: reader.readDateTime(offsets[1]),
    key: reader.readString(offsets[2]),
  );
  object.unReadMessageCount = reader.readLong(offsets[3]);
  return object;
}

P _chatConversationV2DeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatConversationV2GetId(ChatConversationV2 object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _chatConversationV2GetLinks(
    ChatConversationV2 object) {
  return [object.first, object.second, object.lastMessage];
}

void _chatConversationV2Attach(
    IsarCollection<dynamic> col, Id id, ChatConversationV2 object) {
  object.first.attach(col, col.isar.collection<User>(), r'first', id);
  object.second.attach(col, col.isar.collection<User>(), r'second', id);
  object.lastMessage
      .attach(col, col.isar.collection<ChatMessageV2>(), r'lastMessage', id);
}

extension ChatConversationV2ByIndex on IsarCollection<ChatConversationV2> {
  Future<ChatConversationV2?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  ChatConversationV2? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<ChatConversationV2?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<ChatConversationV2?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(ChatConversationV2 object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(ChatConversationV2 object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<ChatConversationV2> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<ChatConversationV2> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension ChatConversationV2QueryWhereSort
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QWhere> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatConversationV2QueryWhere
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QWhereClause> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterWhereClause>
      keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ChatConversationV2QueryFilter
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QFilterCondition> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blocks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blocks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blocks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blocks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blocks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blocks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blocks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blocks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blocks',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blocks',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      blocksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'blocks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      unReadMessageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unReadMessageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      unReadMessageCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unReadMessageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      unReadMessageCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unReadMessageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      unReadMessageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unReadMessageCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChatConversationV2QueryObject
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QFilterCondition> {}

extension ChatConversationV2QueryLinks
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QFilterCondition> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      first(FilterQuery<User> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'first');
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      firstIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'first', 0, true, 0, true);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      second(FilterQuery<User> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'second');
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      secondIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'second', 0, true, 0, true);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      lastMessage(FilterQuery<ChatMessageV2> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'lastMessage');
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterFilterCondition>
      lastMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'lastMessage', 0, true, 0, true);
    });
  }
}

extension ChatConversationV2QuerySortBy
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QSortBy> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      sortByUnReadMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unReadMessageCount', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      sortByUnReadMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unReadMessageCount', Sort.desc);
    });
  }
}

extension ChatConversationV2QuerySortThenBy
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QSortThenBy> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByUnReadMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unReadMessageCount', Sort.asc);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QAfterSortBy>
      thenByUnReadMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unReadMessageCount', Sort.desc);
    });
  }
}

extension ChatConversationV2QueryWhereDistinct
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QDistinct> {
  QueryBuilder<ChatConversationV2, ChatConversationV2, QDistinct>
      distinctByBlocks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blocks');
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatConversationV2, ChatConversationV2, QDistinct>
      distinctByUnReadMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unReadMessageCount');
    });
  }
}

extension ChatConversationV2QueryProperty
    on QueryBuilder<ChatConversationV2, ChatConversationV2, QQueryProperty> {
  QueryBuilder<ChatConversationV2, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ChatConversationV2, List<String>, QQueryOperations>
      blocksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blocks');
    });
  }

  QueryBuilder<ChatConversationV2, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ChatConversationV2, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<ChatConversationV2, int, QQueryOperations>
      unReadMessageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unReadMessageCount');
    });
  }
}
