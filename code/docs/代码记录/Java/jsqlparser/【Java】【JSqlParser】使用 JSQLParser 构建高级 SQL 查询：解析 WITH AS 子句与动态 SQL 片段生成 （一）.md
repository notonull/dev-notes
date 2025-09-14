---
title: 【Java】【jsqlparser】基于JSQLParser构建SQL语法：解析 WITH AS 子句与动态 SQL 片段生成高级查询语句 （一）
copyright: CC-BY-4.0
tags:
  - java
  - jsqlparser
createTime: 2025/04/13 00:54:42
permalink: /blog/tderbfpt/
---

## 一、简介

- JSQLParser 实现 高级 SQL 查询，通过 WITH AS 子句 构建复杂的 SELECT 查询。展示动态 SQL 生成，并结合 聚合函数（如 `SUM`、`MAX`）、逻辑运算符（如 `AND`、`OR`）、连接操作符（如 `JOIN`）以及 子查询 来构建高效的 SQL 查询。通过具体的代码示例。演示包含 多个 WITH 子句、排序、分组、分页等复杂功能的 SQL 查询。

- 当前为应用实例，后续继续补充，jsqlparser 源码实现逻辑等


## 二、前置准备

### 1.maven配置

| 序号 | 名称         | 版本   | 重要   |
| ---- | ------------ | ------ | ------ |
| 2    | `Jsqlparser` | 4.9    | 必须   |
| 3    | `Hutool`     | 5.8.19 | 非必须 |
| 5    | `Lombok`     | -      | 非必须 |

```XML
<dependency>
    <groupId>com.github.jsqlparser</groupId>
    <artifactId>jsqlparser</artifactId>
    <version>4.9</version>
</dependency>
```

## 三、代码实现

### 1.SQL标志符 Token

```java
@AllArgsConstructor
@Getter
public enum SqlToken {

    //集合标志

    UNION_ALL("并集", "UNION ALL"),

    UNION_DISTINCT("去重并集", "UNION DISTINCT"),

    UNION("去重并集", "UNION ALL"),

    EXCEPT("差集", "EXCEPT"),

    MINUS("差集", "MINUS"),

    INTERSECT("交集", "INTERSECT"),

    // 比较符
    EQ("等于", "="),

    NEQ("不等于", "<>"),

    GT("大于", ">"),

    LT("小于", "<"),

    GTE("大于等于", ">="),

    LTE("小于等于", "<="),

    // 特殊比较符

    LIKE("类似", "LIKE"),

    NOT_LIKE("不类似", "NOT LIKE"),

    IN("包含", "IN"),

    NOT_IN("不包含", "NOT IN"),

    IS_NULL("是空", "IS NULL"),

    IS_NOT_NULL("不是空", "IS NOT NULL"),

    BETWEEN("在...之间", "BETWEEN"),

    ADD("加", "+"),

    SUB("减", "-"),

    MUL("乘", "*"),

    DIV("除", "/"),

    MOD("取余", "%"),

    // 逻辑运算符
    AND("与", "AND"),

    OR("或", "OR"),

    NOT("非", "NOT"),


    // 特殊符号
    NULL("空值", "NULL"),

    TRUE("真", "TRUE"),

    FALSE("假", "FALSE"),

    QM("问号", "?"),

    COLON("冒号", ":"),

    DOT("点", "."),

    COMMA("逗号", ","),

    SEM("分号", ";"),

    // 括号和分隔符
    LEFT_PARENTHESIS("左括号", "("),

    RIGHT_PARENTHESIS("右括号", ")"),

    LEFT_BRACKET("左中括号", "["),

    RIGHT_BRACKET("右中括号", "]"),

    LEFT_BRACE("左花括号", "{"),

    RIGHT_BRACE("右花括号", "}"),

    ON("在...条件下", "ON"),

    CONCAT("字符串连接", "||"),
    
    //关联符

    COALESCE("合并", "COALESCE"),

    LEFT_JOIN("左连接", "LEFT JOIN"),

    RIGHT_JOIN("右连接", "RIGHT JOIN"),

    INNER_JOIN("内连接", "INNER JOIN"),

    FULL_JOIN("全连接", "FULL JOIN"),


    // 其他
    EOF("EOF", "End of SQL statement");

    private final String name;
    private final String expr;

}
```



### 2.SQL表达式解析

#### 2.1 查询表达式 

```java
public static Select parseSelectSqlExpr(String selectSql) {
    Statement parse = null;
    try {
        parse = CCJSqlParserUtil.parse(selectSql);
    } catch (JSQLParserException e) {
        throw new RuntimeException(e);
    }
    if (parse instanceof Select) {
        return (Select) parse;
    }
    throw new RuntimeException("not a valid select statement");
}
```



#### 2.2 值表达式 

```java
public static Expression parseValueExpr(Object value) {
    if (NumberUtil.isNumber(value.toString())) {
        return new LongValue(value.toString());
    } else if (value instanceof Date) {
        String format = DateUtil.format((Date) value, DatePattern.NORM_DATETIME_PATTERN);
        return new DateValue(format);
    } else {
        return new StringValue(value.toString());
    }
}
```



#### 2.3 SQL片段

```java
public static Expression parseSqlExpr(String exprStr) {
    try {
        return CCJSqlParserUtil.parseExpression(exprStr);
    } catch (Exception exception) {
        throw new RuntimeException("not a valid sql statement");
    }
}
```



### 3. SQL表达式创建

#### 3.1 列 column

```java
public static Expression createColumnExpr(String tableAlise, String columnName) {
    if (StrUtil.isNotBlank(tableAlise)) {
        return new Column(tableAlise + SqlToken.DOT.getExpr() + columnName);
    }
    return new Column(columnName);
}
```



#### 3.2 表 Table

```java
public static Table createTableExpr(String tableName, String alise) {
    Table table = new Table();
    table.setName(tableName);
    if (StrUtil.isNotBlank(alise)) {
        table.setAlias(new Alias(alise));
    }
    return table;
}
```



#### 3.3 查询项 SelectItem

```java
public static SelectItem createSelectItemExpr(String tableAlise, String columnName, String alise) {
    Expression col = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Alias alias = StrUtil.isNotBlank(alise) ? new Alias(alise) : null;
    return new SelectItem(col, alias);
}

public static SelectItem parseSelectItemExpr(String columnExpr, String alise) {
    Expression expression = SqlExprUtil.parseSqlExpr(columnExpr);
    return new SelectItem(expression, new Alias(alise));
}

public static SelectItem createSelectItemExpr(Expression expression, String alise) {
    return new SelectItem(expression, new Alias(alise));
}
```



#### 3.4 条件 Condition

##### 3.4.1 条件 Conditon

```java
public static Expression createConditionExpr(String tableAlise, String columnName, SqlToken condition, List<Object> values) {
    switch (condition) {
        case EQ:
            return SqlExprUtil.createEqConditionExpr(tableAlise, columnName, CollUtil.get(values, 0));
        case NEQ:
            return SqlExprUtil.createNeqConditionExpr(tableAlise, columnName, CollUtil.get(values, 0));
        case GT:
            return SqlExprUtil.createGtConditionExpr(tableAlise, columnName, CollUtil.get(values, 0));
        case GTE:
            return SqlExprUtil.createGteConditionExpr(tableAlise, columnName, CollUtil.get(values, 0));
        case LT:
            return SqlExprUtil.createLtConditionExpr(tableAlise, columnName, CollUtil.get(values, 0));
        case LTE:
            return SqlExprUtil.createLteConditionExpr(tableAlise, columnName, CollUtil.get(values, 0));
        case BETWEEN:
            return SqlExprUtil.createBetweenConditionExpr(tableAlise, columnName, CollUtil.get(values, 0), CollUtil.get(values, 1));
        case LIKE:
            return SqlExprUtil.createLikeConditionExpr(tableAlise, columnName, CollUtil.get(values, 0), false);
        case NOT_LIKE:
            return SqlExprUtil.createLikeConditionExpr(tableAlise, columnName, CollUtil.get(values, 0), true);
        case IS_NULL:
            return SqlExprUtil.createIsNullConditionExpr(tableAlise, columnName, false);
        case IS_NOT_NULL:
            return SqlExprUtil.createIsNullConditionExpr(tableAlise, columnName, true);
        case IN:
            return SqlExprUtil.createInConditionExpr(tableAlise, columnName, values, false);
        case NOT_IN:
            return SqlExprUtil.createInConditionExpr(tableAlise, columnName, values, true);
        default:
            throw new RuntimeException("not a valid condition expr statement");
    }
}
```



##### 3.4.2 等于 Eq

```java
public static Expression createEqConditionExpr(String tableAlise, String columnName, Object value) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createEqConditionExpr(columnExpr, valueExpr);
}


public static Expression createEqConditionExpr(Expression columnExpr, Expression valueExpr) {
    return new EqualsTo(columnExpr, valueExpr);
}
```

##### 3.4.3 不等于 Neq

```java
public static Expression createNeqConditionExpr(String tableAlise, String columnName, Object value) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createNeqConditionExpr(columnExpr, valueExpr);
}

public static Expression createNeqConditionExpr(Expression columnExpr, Expression valueExpr) {
    return new NotEqualsTo(columnExpr, valueExpr);
}
```



##### 3.4.4 大于 Gt

```java
public static Expression createGtConditionExpr(String tableAlise, String columnName, Object value) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createGtConditionExpr(columnExpr, valueExpr);
}

public static Expression createGtConditionExpr(Expression columnExpr, Expression valueExpr) {
    GreaterThan greaterThan = new GreaterThan();
    greaterThan.withLeftExpression(columnExpr);
    greaterThan.withRightExpression(valueExpr);
    return greaterThan;
}
```



##### 3.4.5 大于等于 Gte

```java
public static Expression createGteConditionExpr(String tableAlise, String columnName, Object value) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createGteConditionExpr(columnExpr, valueExpr);
}


public static Expression createGteConditionExpr(Expression columnExpr, Expression valueExpr) {
    GreaterThanEquals greaterThanEquals = new GreaterThanEquals();
    greaterThanEquals.withLeftExpression(columnExpr);
    greaterThanEquals.withRightExpression(valueExpr);
    return greaterThanEquals;
}
```



##### 3.4.6 小于 Lt

```java
public static Expression createLtConditionExpr(String tableAlise, String columnName, Object value) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createLtConditionExpr(columnExpr, valueExpr);
}

public static Expression createLtConditionExpr(Expression columnExpr, Expression valueExpr) {
    MinorThan greaterThan = new MinorThan();
    greaterThan.withLeftExpression(columnExpr);
    greaterThan.withRightExpression(valueExpr);
    return greaterThan;
}
```



##### 3.4.7 小于等于 Lte

```java
public static Expression createLteConditionExpr(String tableAlise, String columnName, Object value) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createLteConditionExpr(columnExpr, valueExpr);
}

public static Expression createLteConditionExpr(Expression columnExpr, Expression valueExpr) {
    MinorThanEquals minorThanEquals = new MinorThanEquals();
    minorThanEquals.withLeftExpression(columnExpr);
    minorThanEquals.withRightExpression(valueExpr);
    return minorThanEquals;
}
```



##### 3.4.8 范围 Between

```java
public static Expression createBetweenConditionExpr(String tableAlise, String columnName, Object startValue, Object endValue) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression startValueExpr = SqlExprUtil.parseValueExpr(startValue);
    Expression endValueExpr = SqlExprUtil.parseValueExpr(endValue);
    return SqlExprUtil.createBetweenConditionExpr(columnExpr, startValueExpr, endValueExpr);
}

public static Expression createBetweenConditionExpr(Expression columnExpr, Expression startValueExpr, Expression endValueExpr) {
    Between between = new Between().withLeftExpression(columnExpr);
    between.withBetweenExpressionStart(startValueExpr);
    between.withBetweenExpressionEnd(endValueExpr);
    return between;
}
```



##### 3.4.9 模糊 Like/NotLike

```java
public static Expression createLikeConditionExpr(String tableAlise, String columnName, Object value, Boolean isNot) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    Expression valueExpr = SqlExprUtil.parseValueExpr(value);
    return SqlExprUtil.createLikeConditionExpr(columnExpr, valueExpr, isNot);
}

public static Expression createLikeConditionExpr(Expression columnExpr, Expression valuesExpr, Boolean isNot) {
    LikeExpression likeExpression = new LikeExpression();
    likeExpression.setNot(isNot);
    likeExpression.setLeftExpression(columnExpr);
    likeExpression.setRightExpression(valuesExpr);
    return likeExpression;
}
```



##### 3.4.10 匹配 In/NotIn

```java
public static Expression createInConditionExpr(String tableAlise, String columnName, List<Object> values, Boolean isNot) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    ExpressionList expressionList = new ExpressionList();
    for (Object value : values) {
        expressionList.addExpression(SqlExprUtil.parseValueExpr(value));
    }
    return SqlExprUtil.createInConditionExpr(columnExpr, expressionList, isNot);
}

public static Expression createInConditionExpr(Expression columnExpr, ExpressionList valuesExpr, Boolean isNot) {
    InExpression inExpression = new InExpression(columnExpr, valuesExpr);
    inExpression.setNot(true);
    return inExpression;
}
```



##### 3.4.11 判空 IsNull/IsNotNull

```java
public static Expression createIsNullConditionExpr(String tableAlise, String columnName, Boolean isNot) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    return SqlExprUtil.createIsNullConditionExpr(columnExpr, isNot);
}

public static Expression createIsNullConditionExpr(Expression columnExpr, Boolean isNot) {
    IsNullExpression isNullExpression = new IsNullExpression();
    isNullExpression.setNot(isNot);
    isNullExpression.setLeftExpression(columnExpr);
    return isNullExpression;
}
```



#### 3.5 逻辑符 LogicalOperator

##### 3.5.1 逻辑符 LogicalOperator

```java
public static Expression createLogicalOperatorExpr(SqlToken LogicalOperator, Expression leftConditionExpr, Expression rightConditionExpr) {
    switch (LogicalOperator) {
        case AND:
            return SqlExprUtil.createAndLogicalOperatorExpr(leftConditionExpr, rightConditionExpr);
        case OR:
            return SqlExprUtil.createOrLogicalOperatorExpr(leftConditionExpr, rightConditionExpr);
        case NOT:
            return SqlExprUtil.createNotLogicalOperatorExpr(leftConditionExpr);
        default:
            throw new RuntimeException("not a valid LogicalOperator");
    }
}
```



##### 3.5.2 与 And

```java
public static Expression createAndLogicalOperatorExpr(Expression leftConditionExpr, Expression rightConditionExpr) {
    return new AndExpression(leftConditionExpr, rightConditionExpr);
}
```



##### 3.5.3 或 Or

```java
public static Expression createOrLogicalOperatorExpr(Expression leftConditionExpr, Expression rightConditionExpr) {
    return new OrExpression(leftConditionExpr, rightConditionExpr);
}
```



##### 3.5.4 非 Not

```java
public static Expression createNotLogicalOperatorExpr(Expression conditionExpr) {
    return new NotExpression(conditionExpr);
}
```



#### 3.6 Case

##### 3.6.1 When

```java
public static WhenClause createWhenItemExpr(String tableAlise, String columnName, SqlToken conditionType, List<Object> comparativeValues, Object value) {
    WhenClause whenClause = new WhenClause();
    Expression conditionExpr = SqlExprUtil.createConditionExpr(tableAlise, columnName, conditionType, comparativeValues);
    whenClause.setWhenExpression(conditionExpr);
    whenClause.setThenExpression(SqlExprUtil.parseValueExpr(value));
    return whenClause;
}

public static WhenClause createWhenItemExpr(String tableAlise, String columnName, SqlToken conditionType, List<Object> comparativeValues, String targetTableAlise, String targetColumnName) {
    WhenClause whenClause = new WhenClause();
    Expression conditionExpr = SqlExprUtil.createConditionExpr(tableAlise, columnName, conditionType, comparativeValues);
    whenClause.setWhenExpression(conditionExpr);
    whenClause.setThenExpression(SqlExprUtil.createColumnExpr(targetTableAlise, targetColumnName));
    return whenClause;
}

public static WhenClause createWhenItemExpr(Expression whenExpr, Expression thenExpr) {
    WhenClause whenClause = new WhenClause();
    whenClause.setWhenExpression(whenExpr);
    whenClause.setThenExpression(thenExpr);
    return whenClause;
}
```



##### 3.6.2 Case

```java
public static CaseExpression createCaseExpr(List<WhenClause> whenExprList, Expression elseExpr) {
    CaseExpression caseExpression = new CaseExpression();
    caseExpression.setWhenClauses(whenExprList);
    caseExpression.setElseExpression(elseExpr);
    return caseExpression;
}
```



#### 3.7 函数 Function

##### 3.7.1 SUM/AVG/MAX...

```java
public static Function createFuncExpr(String func, List<Expression> exprList) {
    Function function = new Function();
    function.setName(func);
    function.setParameters(SqlExprUtil.createExpressionList(exprList));
    return function;
}
```



#### 3.8 关联 Join

```java
public static Join createJoinExpr(SqlToken joinType, Table rightTable, List<Expression> conditions) {
    Join join = new Join();
    join.setRightItem(rightTable);
    if (joinType == SqlToken.LEFT_JOIN) {
        join.setLeft(true);
    } else if (joinType == SqlToken.RIGHT_JOIN) {
        join.setRight(true);
    } else if (joinType == SqlToken.INNER_JOIN) {
        join.setInner(true);
    } else if (joinType == SqlToken.FULL_JOIN) {
        join.setFull(true);
    } else if (joinType == SqlToken.COALESCE) {
        join.setCross(true);
    }
    if (conditions != null) {
        join.setOnExpressions(conditions);
    }
    return join;
}
```



#### 3.9 排序 Order

```java
public static OrderByElement createOrderExpr(String tableAlise, String columnName, Boolean isAsc) {
    Expression columnExpr = SqlExprUtil.createColumnExpr(tableAlise, columnName);
    return SqlExprUtil.createOrderExpr(columnExpr, isAsc);
}

public static OrderByElement createOrderExpr(Expression leftExpr, Boolean isAsc) {
    OrderByElement order = new OrderByElement();
    order.setExpression(leftExpr);
    order.setAsc(isAsc);
    return order;
}
```



#### 3.10 分组 Group

```java
public static GroupByElement createGroupsExpr(Expression... expr) {
    GroupByElement group = new GroupByElement();
    group.setGroupByExpressions(SqlExprUtil.createExpressionList(expr));
    return group;
}

public static GroupByElement createGroupsExpr(List<Expression> expr) {
    GroupByElement group = new GroupByElement();
    group.setGroupByExpressions(SqlExprUtil.createExpressionList(expr));
    return group;
}
```



#### 3.11 限制/分页 Limit

##### 3.11.1 限制

```java
public static Limit createLimitExpr(Long offset, Long rowCount) {
    Limit limit = new Limit();
    limit.setOffset(SqlExprUtil.parseValueExpr(offset));
    limit.setRowCount(SqlExprUtil.parseValueExpr(rowCount));
    return limit;
}
```



##### 3.11.2 分页

```java
public static Limit createPageExpr(Long pageNo, Long pageSize) {
    if (pageNo < 1L) {
        pageNo = 1L;
    }
    Long offset = (pageNo - 1) * pageSize;
    return SqlExprUtil.createLimitExpr(offset, pageSize);
}
```



#### 3.12 集合 SetOperation

##### 3.12.1 集合 SetOperation

```java
public static SetOperation createSetOperationExpr(SqlToken setOperationType) {
    switch (setOperationType) {
        case UNION:
        case UNION_DISTINCT:
            return SqlExprUtil.createUnionSetOperationExpr(false);
        case UNION_ALL:
            return SqlExprUtil.createUnionSetOperationExpr(true);
        case INTERSECT:
            return SqlExprUtil.createIntersectSetOperationExpr();
        case EXCEPT:
            return SqlExprUtil.createExceptSetOperationExpr();
        case MINUS:
            //其实和EXCEPT一样 oracle 限定
            return SqlExprUtil.createMinusSetOperationExpr();
        default:
            throw new RuntimeException("not a valid setOperationType");
    }
}
```



##### 3.12.2 合集 Union/UnionAll

```java
public static UnionOp createUnionSetOperationExpr(Boolean isAll) {
    UnionOp unionOp = new UnionOp();
    unionOp.setAll(isAll);
    return unionOp;
}
```



##### 3.12.3 差集 Except/Minus

```java
public static ExceptOp createExceptSetOperationExpr() {
    return new ExceptOp();
}

public static MinusOp createMinusSetOperationExpr() {
    return new MinusOp();
}
```



##### 3.12.4 交集 Intersect

```java
public static IntersectOp createIntersectSetOperationExpr() {
    return new IntersectOp();
}
```



#### 3.13 查询 Select

##### 3.13.1 查询语句 Select

```java
public static PlainSelect createSelectExpr(List<WithItem> withSelectItems, List<SelectItem<?>> selectItems, FromItem from, List<Join> joins, Expression where, GroupByElement groups, List<OrderByElement> orders, Limit limit) {
    PlainSelect plainSelect = new PlainSelect();
    plainSelect.setWithItemsList(withSelectItems);
    plainSelect.setSelectItems(selectItems);
    plainSelect.setFromItem(from);
    plainSelect.setJoins(joins);
    plainSelect.setWhere(where);
    plainSelect.setGroupByElement(groups);
    plainSelect.setOrderByElements(orders);
    plainSelect.setLimit(limit);
    return plainSelect;
}
```



##### 3.13.2 With查询语句 WithAsSelect

```java
public static WithItem createWithItemSelectExpr(String alise, Select select) {
    WithItem withItem = new WithItem();
    withItem.setAlias(new Alias(alise));
    if (select instanceof ParenthesedSelect) {
        withItem.setSelect(select);
    } else {
        ParenthesedSelect parenthesedSelect = new ParenthesedSelect();
        parenthesedSelect.setSelect(select);
        withItem.setSelect(parenthesedSelect);
    }
    return withItem;
}
```



##### 3.13.3 带括号的查询语句 ParenthesedSelect 

```java
public static ParenthesedSelect createParenthesizedSubquerySelectExpr(Select select) {
    ParenthesedSelect parenthesedSelect = new ParenthesedSelect();
    parenthesedSelect.setSelect(select);
    return parenthesedSelect;
}
```

## 四、演示操作

### 1.用例演示

#### 1.1 输入

```java
public static void main2() {

        Select selectExpr1 = SqlExprUtil.parseSelectSqlExpr("select tab1.field1,sum(tab2.field2) from table1 tab1 left join table2 tab2 on tab1.field1 = tab2.field1 where tab2.field2 > 100 group by tab1.field1 order by tab1.field1");
        //select 还有下集继承类如：ParenthesedSelect  LateralSubSelect 等
        System.out.println("\n[解析查询语句]\n " + selectExpr1);

        Expression valueExpr1 = SqlExprUtil.parseValueExpr("我是字符串");
        Expression valueExpr2 = SqlExprUtil.parseValueExpr(123);
        System.out.println("\n[解析值]\n " + valueExpr1);


        Expression expr1 = SqlExprUtil.parseSqlExpr("sum(case when tab1.field1 = '我是字符串' then 1 else 0 end) as sumField1");
        System.out.println("\n[解析SQL片段]\n " + expr1);


        Expression columnExpr1 = SqlExprUtil.createColumnExpr("tab1", "field1");
        Expression columnExpr2 = SqlExprUtil.createColumnExpr("tab2", "field1");
        Expression columnExpr3 = SqlExprUtil.createColumnExpr("tab1", "field2");
        System.out.println("\n[创建列]\n " + columnExpr1);


        Table tableExpr1 = SqlExprUtil.createTableExpr("table1", "tab1");
        Table tableExpr2 = SqlExprUtil.createTableExpr("table2", "tab2");
        System.out.println("\n[创建表]\n " + tableExpr1);

        SelectItem selectItemExpr1 = SqlExprUtil.parseSelectItemExpr("sum(case when tab1.field1 = '我是字符串' then 1 else 0 end)", "sumField1");
        System.out.println("\n[创建查询项-根据片段]\n " + selectItemExpr1);

        SelectItem selectItemExpr2 = SqlExprUtil.createSelectItemExpr("tab1", "field1", "field1");
        System.out.println("\n[创建查询项]\n " + selectItemExpr2);

        Expression conditionExpr1 = SqlExprUtil.createConditionExpr("tab1", "field1", SqlToken.EQ, ListUtil.of("我是字符串"));
        System.out.println("\n[创建条件]\n " + conditionExpr1);


        Expression conditionExpr2 = SqlExprUtil.createEqConditionExpr("tab1", "field1", "我是字符串");
        System.out.println("\n[创建等于条件]\n " + conditionExpr2);

        Expression conditionExpr3 = SqlExprUtil.createEqConditionExpr(columnExpr1, valueExpr1);
        System.out.println("\n[创建等于条件-原始]\n " + conditionExpr3);


        Expression conditionExpr4 = SqlExprUtil.createNeqConditionExpr("tab1", "field1", "我是字符串");
        System.out.println("\n[创建不等于条件]\n " + conditionExpr4);

        Expression conditionExpr5 = SqlExprUtil.createNeqConditionExpr(columnExpr1, valueExpr1);
        System.out.println("\n[创建不等于条件-原始]\n " + conditionExpr5);

        Expression conditionExpr6 = SqlExprUtil.createGtConditionExpr("tab1", "field2", 123);
        System.out.println("\n[创建大于条件]\n " + conditionExpr6);

        Expression conditionExpr7 = SqlExprUtil.createGtConditionExpr(columnExpr3, SqlExprUtil.parseValueExpr(123));
        System.out.println("\n[创建大于条件-原始]\n " + conditionExpr7);


        Expression conditionExpr8 = SqlExprUtil.createGteConditionExpr("tab1", "field2", 123);
        System.out.println("\n[创建大于等于条件]\n " + conditionExpr8);

        Expression conditionExpr9 = SqlExprUtil.createGteConditionExpr(columnExpr3, SqlExprUtil.parseValueExpr(123));
        System.out.println("\n[创建大于等于条件-原始]\n " + conditionExpr9);

        Expression conditionExpr10 = SqlExprUtil.createLtConditionExpr("tab1", "field2", 123);
        System.out.println("\n[创建小于条件]\n " + conditionExpr10);

        Expression conditionExpr11 = SqlExprUtil.createLtConditionExpr(columnExpr3, SqlExprUtil.parseValueExpr(123));
        System.out.println("\n[创建小于条件-原始]\n " + conditionExpr11);

        Expression conditionExpr12 = SqlExprUtil.createLteConditionExpr("tab1", "field2", 123);
        System.out.println("\n[创建小于条件]\n " + conditionExpr12);

        Expression conditionExpr13 = SqlExprUtil.createLteConditionExpr(columnExpr3, SqlExprUtil.parseValueExpr(123));
        System.out.println("\n[创建小于条件-原始]\n " + conditionExpr13);

        Expression conditionExpr14 = SqlExprUtil.createBetweenConditionExpr("tab1", "field2", 123, 125);
        System.out.println("\n[创建范围条件]\n " + conditionExpr14);

        Expression conditionExpr15 = SqlExprUtil.createBetweenConditionExpr(columnExpr3, valueExpr2, SqlExprUtil.parseValueExpr(125));
        System.out.println("\n[创建范围条件-原始]\n " + conditionExpr15);

        Expression conditionExpr16 = SqlExprUtil.createLikeConditionExpr("tab1", "field1", "我是字符串", false);
        System.out.println("\n[创建Like条件]\n " + conditionExpr16);

        Expression conditionExpr17 = SqlExprUtil.createLikeConditionExpr(columnExpr1, valueExpr1, false);
        System.out.println("\n[创建Like条件-原始]\n " + conditionExpr17);

        Expression conditionExpr18 = SqlExprUtil.createInConditionExpr("tab1", "field1", ListUtil.of("我是字符串", "我是字符串2"), false);
        System.out.println("\n[创建In条件]\n " + conditionExpr18);

        Expression conditionExpr19 = SqlExprUtil.createInConditionExpr(columnExpr1, SqlExprUtil.createExpressionList(valueExpr1, SqlExprUtil.parseValueExpr("我是字符串2")), false);
        System.out.println("\n[创建In条件-原始]\n " + conditionExpr19);

        Expression conditionExpr20 = SqlExprUtil.createIsNullConditionExpr("tab1", "field1", false);
        System.out.println("\n[创建判空条件]\n " + conditionExpr20);

        Expression conditionExpr21 = SqlExprUtil.createIsNullConditionExpr(columnExpr1, false);
        System.out.println("\n[创建判空条件-原始]\n " + conditionExpr21);


        Expression logicalOperatorExpr1 = SqlExprUtil.createLogicalOperatorExpr(SqlToken.AND, conditionExpr8, conditionExpr10);
        System.out.println("\n[创建逻辑符]\n " + logicalOperatorExpr1);

        Expression logicalOperatorExpr2 = SqlExprUtil.createAndLogicalOperatorExpr(conditionExpr8, conditionExpr10);
        System.out.println("\n[创建And逻辑符]\n " + logicalOperatorExpr2);

        Expression logicalOperatorExpr3 = SqlExprUtil.createOrLogicalOperatorExpr(conditionExpr8, conditionExpr10);
        System.out.println("\n[创建Or逻辑符]\n " + logicalOperatorExpr3);

        Expression logicalOperatorExpr4 = SqlExprUtil.createNotLogicalOperatorExpr(conditionExpr8);
        System.out.println("\n[创建Not逻辑符]\n " + logicalOperatorExpr4);

        //"sum(case when tab1.field1 = '我是字符串' then 1 else 0 end)"
        WhenClause whenItemExpr1 = SqlExprUtil.createWhenItemExpr("tab1", "field1", SqlToken.EQ, ListUtil.of("我是字符串"), 1);
        System.out.println("\n[创建Case When项片段]\n " + whenItemExpr1);

        WhenClause whenItemExpr2 = SqlExprUtil.createWhenItemExpr("tab1", "field1", SqlToken.EQ, ListUtil.of("我是字符串"), "tab1", "field1");
        System.out.println("\n[创建Case When项片段]\n " + whenItemExpr2);

        WhenClause whenItemExpr3 = SqlExprUtil.createWhenItemExpr(conditionExpr2, SqlExprUtil.parseValueExpr(1));
        System.out.println("\n[创建Case When项片段 - 原始]\n " + whenItemExpr3);

        CaseExpression caseExpr1 = SqlExprUtil.createCaseExpr(ListUtil.of(whenItemExpr1), SqlExprUtil.parseValueExpr(0));
        System.out.println("\n[创建Case片段]\n " + caseExpr1);


        Function sumExpr = SqlExprUtil.createFuncExpr("Sum", new ExpressionList<Expression>(caseExpr1));
        System.out.println("\n[创建Sum片段]\n " + sumExpr);

        Function maxExpr = SqlExprUtil.createFuncExpr("max", new ExpressionList<Expression>(columnExpr3));
        System.out.println("\n[创建Max片段]\n " + maxExpr);

        Expression conditionExpr22 = SqlExprUtil.createEqConditionExpr(columnExpr1, columnExpr2);
        Join joinExpr1 = SqlExprUtil.createJoinExpr(SqlToken.LEFT_JOIN, tableExpr2, ListUtil.of(conditionExpr22));
        System.out.println("\n[创建Join关联]\n " + joinExpr1);

        OrderByElement orderExpr1 = SqlExprUtil.createOrderExpr("tab1", "field1", true);
        System.out.println("\n[创建排序]\n " + orderExpr1);

        OrderByElement orderExpr2 = SqlExprUtil.createOrderExpr(columnExpr1, true);
        System.out.println("\n[创建排序-原始]\n " + orderExpr2);

        GroupByElement groupsExpr1 = SqlExprUtil.createGroupsExpr(columnExpr1);
        System.out.println("\n[创建分组]\n " + groupsExpr1);

        Limit limitExpr1 = SqlExprUtil.createLimitExpr(0L, 10L);
        System.out.println("\n[创建Limit]\n " + limitExpr1);

        Limit limitExpr2 = SqlExprUtil.createPageExpr(1L, 10L);
        System.out.println("\n[创建PageLimit]\n " + limitExpr2);

        PlainSelect selectExpr2 = SqlExprUtil.createSelectExpr(null,
                ListUtil.of(selectItemExpr1, selectItemExpr2),
                tableExpr1,
                ListUtil.of(joinExpr1),
                logicalOperatorExpr2,
                groupsExpr1,
                ListUtil.of(orderExpr1),
                limitExpr2
        );
        System.out.println("\n[创建select]\n " + selectExpr2);

        WithItem selectExpr3 = SqlExprUtil.createWithItemSelectExpr("test1", selectExpr2);
        System.out.println("\n[创建WithAsSelect]\n " + selectExpr3);

        SetOperationList selectExpr6 = SqlExprUtil.createSetOperationSelectExpr(SqlToken.UNION, ListUtil.of(selectExpr2, selectExpr2));
        System.out.println("\n[创建集合操作查询]\n " + selectExpr6);


        SetOperation setOperationExpr1 = SqlExprUtil.createSetOperationExpr(SqlToken.UNION);
        System.out.println("\n[创建集合操作符]\n " + setOperationExpr1);

        UnionOp setOperationExpr2 = SqlExprUtil.createUnionSetOperationExpr(true);
        System.out.println("\n[创建集合Union操作符]\n " + setOperationExpr2);

        UnionOp setOperationExpr3 = SqlExprUtil.createUnionSetOperationExpr(false);
        System.out.println("\n[创建集合UnionAll操作符]\n " + setOperationExpr3);

        ExceptOp setOperationExpr4 = SqlExprUtil.createExceptSetOperationExpr();
        System.out.println("\n[创建差集Except操作符]\n " + setOperationExpr4);

        MinusOp setOperationExpr5 = SqlExprUtil.createMinusSetOperationExpr();
        System.out.println("\n[创建差集Minus操作符]\n " + setOperationExpr5);

        IntersectOp setOperationExpr6 = SqlExprUtil.createIntersectSetOperationExpr();
        System.out.println("\n[创建交集Intersect操作符]\n " + setOperationExpr6);

    }
```



#### 1.2 输出

```sql
[解析查询语句]
 SELECT tab1.field1, sum(tab2.field2) FROM table1 tab1 LEFT JOIN table2 tab2 ON tab1.field1 = tab2.field1 WHERE tab2.field2 > 100 GROUP BY tab1.field1 ORDER BY tab1.field1

[解析值]
 '我是字符串'

[解析SQL片段]
 sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END)

[创建列]
 tab1.field1

[创建表]
 table1 AS tab1

[创建查询项-根据片段]
 sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END) AS sumField1

[创建查询项]
 tab1.field1 AS field1

[创建条件]
 tab1.field1 = '我是字符串'

[创建等于条件]
 tab1.field1 = '我是字符串'

[创建等于条件-原始]
 tab1.field1 = '我是字符串'

[创建不等于条件]
 tab1.field1 <> '我是字符串'

[创建不等于条件-原始]
 tab1.field1 <> '我是字符串'

[创建大于条件]
 tab1.field2 > 123

[创建大于条件-原始]
 tab1.field2 > 123

[创建大于等于条件]
 tab1.field2 >= 123

[创建大于等于条件-原始]
 tab1.field2 >= 123

[创建小于条件]
 tab1.field2 < 123

[创建小于条件-原始]
 tab1.field2 < 123

[创建小于条件]
 tab1.field2 <= 123

[创建小于条件-原始]
 tab1.field2 <= 123

[创建范围条件]
 tab1.field2 BETWEEN 123 AND 125

[创建范围条件-原始]
 tab1.field2 BETWEEN 123 AND 125

[创建Like条件]
 tab1.field1 LIKE '我是字符串'

[创建Like条件-原始]
 tab1.field1 LIKE '我是字符串'

[创建In条件]
 tab1.field1 NOT IN '我是字符串', '我是字符串2'

[创建In条件-原始]
 tab1.field1 NOT IN '我是字符串', '我是字符串2'

[创建判空条件]
 tab1.field1 IS NULL

[创建判空条件-原始]
 tab1.field1 IS NULL

[创建逻辑符]
 tab1.field2 >= 123 AND tab1.field2 < 123

[创建And逻辑符]
 tab1.field2 >= 123 AND tab1.field2 < 123

[创建Or逻辑符]
 tab1.field2 >= 123 OR tab1.field2 < 123

[创建Not逻辑符]
 NOT tab1.field2 >= 123

[创建Case When项片段]
 WHEN tab1.field1 = '我是字符串' THEN 1

[创建Case When项片段]
 WHEN tab1.field1 = '我是字符串' THEN tab1.field1

[创建Case When项片段 - 原始]
 WHEN tab1.field1 = '我是字符串' THEN 1

[创建Case片段]
 CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END

[创建Sum片段]
 Sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END)

[创建Max片段]
 max(tab1.field2)

[创建Join关联]
 LEFT JOIN table2 AS tab2 ON tab1.field1 = tab2.field1

[创建排序]
 tab1.field1

[创建排序-原始]
 tab1.field1

[创建分组]
 GROUP BY tab1.field1

[创建Limit]
  LIMIT 0, 10

[创建PageLimit]
  LIMIT 0, 10

[创建select]
 SELECT sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END) AS sumField1, tab1.field1 AS field1 FROM table1 AS tab1 LEFT JOIN table2 AS tab2 ON tab1.field1 = tab2.field1 WHERE tab1.field2 >= 123 AND tab1.field2 < 123 GROUP BY tab1.field1 ORDER BY tab1.field1 LIMIT 0, 10

[创建WithAsSelect]
 test1 AS (SELECT sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END) AS sumField1, tab1.field1 AS field1 FROM table1 AS tab1 LEFT JOIN table2 AS tab2 ON tab1.field1 = tab2.field1 WHERE tab1.field2 >= 123 AND tab1.field2 < 123 GROUP BY tab1.field1 ORDER BY tab1.field1 LIMIT 0, 10)

[创建集合操作查询]
 SELECT sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END) AS sumField1, tab1.field1 AS field1 FROM table1 AS tab1 LEFT JOIN table2 AS tab2 ON tab1.field1 = tab2.field1 WHERE tab1.field2 >= 123 AND tab1.field2 < 123 GROUP BY tab1.field1 ORDER BY tab1.field1 LIMIT 0, 10 UNION SELECT sum(CASE WHEN tab1.field1 = '我是字符串' THEN 1 ELSE 0 END) AS sumField1, tab1.field1 AS field1 FROM table1 AS tab1 LEFT JOIN table2 AS tab2 ON tab1.field1 = tab2.field1 WHERE tab1.field2 >= 123 AND tab1.field2 < 123 GROUP BY tab1.field1 ORDER BY tab1.field1 LIMIT 0, 10

[创建集合操作符]
 UNION

[创建集合Union操作符]
 UNION ALL

[创建集合UnionAll操作符]
 UNION

[创建差集Except操作符]
 EXCEPT

[创建差集Minus操作符]
 MINUS

[创建交集Intersect操作符]
 INTERSECT
```

### 2.高级查询

#### 2.1 输入

**包含with as 等复杂查询**

```java
public static void main1() {
        Table tableExpr = SqlExprUtil.createTableExpr("TABLE", null);
        WhenClause whenItemExpr = SqlExprUtil.createWhenItemExpr(null, "IndexCode", SqlToken.EQ, ListUtil.of("R_FIELD"), null, "IndexValue");
        CaseExpression caseExpr = SqlExprUtil.createCaseExpr(ListUtil.of(whenItemExpr), SqlExprUtil.parseValueExpr(0));
        Function sumExpr = SqlExprUtil.createFuncExpr("sum", ListUtil.of(caseExpr));
        SelectItem fieldExpr = SqlExprUtil.createSelectItemExpr(sumExpr, "R_FIELD");

        //本期
        Expression cpWhere = SqlExprUtil.createBetweenConditionExpr(null, "DateMonthKey", 202301, 202301);
        PlainSelect selectExpr1 = SqlExprUtil.createSelectExpr(null, ListUtil.of(fieldExpr), tableExpr, null, cpWhere, null, null, null);
        WithItem cpWith = SqlExprUtil.createWithItemSelectExpr("cp", selectExpr1);
        SelectItem cpSelectField = SqlExprUtil.createSelectItemExpr("cp", "R_FIELD", "CP_R_FIELD");
        Table cpTable = SqlExprUtil.createTableExpr(cpWith.getAlias().getName(), null);
        //上期
        Expression ppWhere = SqlExprUtil.createBetweenConditionExpr(null, "DateMonthKey", 202212, 202212);
        PlainSelect selectExpr2 = SqlExprUtil.createSelectExpr(null, ListUtil.of(fieldExpr), tableExpr, null, ppWhere, null, null, null);
        WithItem ppWith = SqlExprUtil.createWithItemSelectExpr("pp", selectExpr2);
        SelectItem ppSelectField = SqlExprUtil.createSelectItemExpr("pp", "R_FIELD", "PP_R_FIELD");
        Table ppTable = SqlExprUtil.createTableExpr(ppWith.getAlias().getName(), null);
        //同期
        Expression spWhere = SqlExprUtil.createBetweenConditionExpr(null, "DateMonthKey", 202201, 202201);
        PlainSelect selectExpr3 = SqlExprUtil.createSelectExpr(null, ListUtil.of(fieldExpr), tableExpr, null, spWhere, null, null, null);
        WithItem spWith = SqlExprUtil.createWithItemSelectExpr("sp", selectExpr3);
        SelectItem spSelectField = SqlExprUtil.createSelectItemExpr("sp", "R_FIELD", "SP_R_FIELD");
        Table spTable = SqlExprUtil.createTableExpr(spWith.getAlias().getName(), null);
        //结果集
        List<SelectItem<?>> selectItems = ListUtil.of(cpSelectField, ppSelectField, spSelectField);
        List<WithItem> withItems = ListUtil.of(cpWith, ppWith, spWith);
        Join ppJoinExpr = SqlExprUtil.createJoinExpr(SqlToken.COALESCE, ppTable, null);
        Join spJoinExpr = SqlExprUtil.createJoinExpr(SqlToken.COALESCE, spTable, null);
        PlainSelect resultSelect = SqlExprUtil.createSelectExpr(withItems, selectItems, cpTable, ListUtil.of(ppJoinExpr, spJoinExpr), null, null, null, null);
        System.out.println(resultSelect);
    }
```

#### 2.2 输出

```sql
WITH 
cp AS (SELECT sum(CASE WHEN IndexCode = 'R_FIELD' THEN IndexValue ELSE 0 END) AS R_FIELD FROM TABLE WHERE DateMonthKey BETWEEN 202301 AND 202301), 
pp AS (SELECT sum(CASE WHEN IndexCode = 'R_FIELD' THEN IndexValue ELSE 0 END) AS R_FIELD FROM TABLE WHERE DateMonthKey BETWEEN 202212 AND 202212),
sp AS (SELECT sum(CASE WHEN IndexCode = 'R_FIELD' THEN IndexValue ELSE 0 END) AS R_FIELD FROM TABLE WHERE DateMonthKey BETWEEN 202201 AND 202201) 
SELECT 
cp.R_FIELD AS CP_R_FIELD, 
pp.R_FIELD AS PP_R_FIELD, 
sp.R_FIELD AS SP_R_FIELD 
FROM 
cp CROSS JOIN pp CROSS JOIN sp
```
