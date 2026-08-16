import {
  BatchDataBuilderLike,
  ClientLike,
  DataBuilderLike,
  DbModule,
  FilterBuilderLike,
  QueryBuilderLike
} from '../model/Types';

/** order_by 数组元素结构 */
class OrderItem {
  field: string;
  direction: string;

  constructor(field: string, direction: string) {
    this.field = field;
    this.direction = direction;
  }
}

/**
 * 数据表查询入口：.from('table') 后选择 list / page / get / insert / insertBatch / update / delete。
 */
class QueryBuilder implements QueryBuilderLike {
  private client: ClientLike;
  private table: string;

  constructor(client: ClientLike, table: string) {
    this.client = client;
    this.table = table;
  }

  list(): FilterBuilderLike {
    return new FilterBuilder(this.client, this.table, 'list');
  }

  page(): FilterBuilderLike {
    return new FilterBuilder(this.client, this.table, 'page');
  }

  get(): FilterBuilderLike {
    return new FilterBuilder(this.client, this.table, 'get');
  }

  insert(): DataBuilderLike {
    return new DataBuilder(this.client, this.table, 'add');
  }

  insertBatch(): BatchDataBuilderLike {
    return new BatchDataBuilder(this.client, this.table, 'addbatch');
  }

  update(): DataBuilderLike {
    return new DataBuilder(this.client, this.table, 'update');
  }

  delete(): FilterBuilderLike {
    return new FilterBuilder(this.client, this.table, 'delete');
  }
}

/**
 * 过滤条件构建器：eq / neq / gt / gte / lt / lte / in / between / like / or / order / page。
 * 生成的 filters 结构与 JS SDK 完全一致。
 */
class FilterBuilder implements FilterBuilderLike {
  protected client: ClientLike;
  protected table: string;
  protected method: string;
  protected filters: Record<string, Object> = {};

  constructor(client: ClientLike, table: string, method: string) {
    this.client = client;
    this.table = table;
    this.method = method;
  }

  private addFilter(field: string, operator: string, value: Object): FilterBuilder {
    const existing: Object | undefined = this.filters[field];
    if (existing === undefined) {
      const emptyFilters: Record<string, Object> = {};
      this.filters[field] = emptyFilters;
    }
    const fieldFilters: Record<string, Object> = this.filters[field] as Record<string, Object>;
    fieldFilters[operator] = value;
    return this;
  }

  eq(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'eq', value);
  }

  neq(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'neq', value);
  }

  gt(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'gt', value);
  }

  gte(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'gte', value);
  }

  lt(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'lt', value);
  }

  lte(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'lte', value);
  }

  in(field: string, values: Object[]): FilterBuilderLike {
    return this.addFilter(field, 'in', values);
  }

  between(field: string, values: Object[]): FilterBuilderLike {
    return this.addFilter(field, 'between', values);
  }

  like(field: string, value: Object): FilterBuilderLike {
    return this.addFilter(field, 'like', value);
  }

  or(callback: (q: FilterBuilderLike) => void): FilterBuilderLike {
    const orList: Object[] | undefined = this.filters['or'] as Object[] | undefined;
    if (orList === undefined) {
      const emptyList: Object[] = [];
      this.filters['or'] = emptyList;
    }
    const sub: FilterBuilder = new FilterBuilder(this.client, this.table, 'or');
    callback(sub);
    const list: Object[] = this.filters['or'] as Object[];
    list.push(sub.build());
    return this;
  }

  page(number: number, size: number): FilterBuilderLike {
    this.filters['current'] = number;
    this.filters['pageSize'] = size;
    return this;
  }

  order(field: string, direction: string = 'asc'): FilterBuilderLike {
    let dir: string = direction.toLowerCase();
    if (dir !== 'desc') {
      dir = 'asc';
    }
    const orderList: Object[] | undefined = this.filters['order_by'] as Object[] | undefined;
    if (orderList === undefined) {
      const emptyList: Object[] = [];
      this.filters['order_by'] = emptyList;
    }
    const item: OrderItem = new OrderItem(field, dir);
    const list: Object[] = this.filters['order_by'] as Object[];
    list.push(item);
    return this;
  }

  build(): Record<string, Object> {
    return this.filters;
  }

  execute(): Promise<Object> {
    const url: string = `/api/data/invoke?table=${this.table}&method=${this.method}`;
    return this.client.request(url, {
      method: 'POST',
      body: JSON.stringify(this.build())
    });
  }
}

/**
 * 数据写入构建器（insert / update）：values/set 提供数据，条件部分复用 FilterBuilder。
 */
class DataBuilder extends FilterBuilder implements DataBuilderLike {
  private data: Record<string, Object> = {};

  constructor(client: ClientLike, table: string, method: string) {
    super(client, table, method);
  }

  values(data: Record<string, Object>): DataBuilderLike {
    this.copyInto(this.data, data);
    return this;
  }

  set(data: Record<string, Object>): DataBuilderLike {
    this.copyInto(this.data, data);
    return this;
  }

  build(): Record<string, Object> {
    const merged: Record<string, Object> = {};
    const filterKeys: string[] = Object.keys(this.filters);
    for (let i = 0; i < filterKeys.length; i++) {
      merged[filterKeys[i]] = this.filters[filterKeys[i]];
    }
    const dataKeys: string[] = Object.keys(this.data);
    for (let i = 0; i < dataKeys.length; i++) {
      merged[dataKeys[i]] = this.data[dataKeys[i]];
    }
    return merged;
  }

  execute(): Promise<Object> {
    const url: string = `/api/data/invoke?table=${this.table}&method=${this.method}`;
    return this.client.request(url, {
      method: 'POST',
      body: JSON.stringify(this.build())
    });
  }

  private copyInto(target: Record<string, Object>, source: Record<string, Object>): void {
    const keys: string[] = Object.keys(source);
    for (let i = 0; i < keys.length; i++) {
      target[keys[i]] = source[keys[i]];
    }
  }
}

/**
 * 批量插入构建器（insertBatch）：body 为对象数组。
 */
class BatchDataBuilder implements BatchDataBuilderLike {
  private client: ClientLike;
  private table: string;
  private method: string;
  private dataArray: Object[] = [];

  constructor(client: ClientLike, table: string, method: string) {
    this.client = client;
    this.table = table;
    this.method = method;
  }

  values(dataArray: Object[]): BatchDataBuilderLike {
    this.dataArray = dataArray;
    return this;
  }

  execute(): Promise<Object> {
    const url: string = `/api/data/invoke?table=${this.table}&method=${this.method}`;
    return this.client.request(url, {
      method: 'POST',
      body: JSON.stringify(this.dataArray)
    });
  }
}

/**
 * 数据库模块实现。
 */
class DbModuleImpl implements DbModule {
  private client: ClientLike;

  constructor(client: ClientLike) {
    this.client = client;
  }

  from(table: string): QueryBuilderLike {
    return new QueryBuilder(this.client, table);
  }
}

/**
 * 创建数据库模块。
 */
export function dbModule(client: ClientLike): DbModule {
  return new DbModuleImpl(client);
}
