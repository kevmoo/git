part of bot_io;

class Console {

  static Iterable<String> getTable(List source,
      List<ColumnDefinition> columns, {includeHeader: false}) {
    requireArgumentNotNull(source, 'source');
    requireArgumentNotNull(columns, 'columns');
    requireArgument(columns.length > 0, 'columns',
        'Must have at least one column');

    //
    // populate cells so we know what data we're dealing with
    // also keep track of the max width of each column
    //

    final headerInclude = includeHeader ? 1 : 0;

    final cells = new Array2d<String>(columns.length, source.length + headerInclude);
    final maxWidths = new List<int>();
    maxWidths.insertRange(0, columns.length, 0);

    if(includeHeader) {
      // populate header first
      for(var i = 0; i < columns.length; i++) {
        final value = columns[i].name;
        maxWidths[i] = math.max(maxWidths[i], value.length);
        cells.set(i, 0, value);
      }
    }

    for(int i = 0; i < source.length; i++) {
      final rowIndex = i + headerInclude;
      for(var col = 0; col < columns.length; col++) {
        final column = columns[col];
        final value = column._mapper(source[i]).trim();
        maxWidths[col] = math.max(maxWidths[col], value.length);
        cells.set(col, rowIndex, value);
      }
    }

    return cells.rows.mappedBy((r) => _getRow(r, maxWidths));
  }

  static String _getRow(List<String> row, List<int> columnWidths) {
    final minBuffer = 3;

    assert(row.length == columnWidths.length);
    final buffer = new StringBuffer();
    int targetWidth = 0;

    for(var i = 0; i < row.length; i++) {
      final value = row[i];
      final width = columnWidths[i];
      assert(value.length <= width);

      while(buffer.length < targetWidth) {
        buffer.add(' ');
      }
      buffer.add(value);

      targetWidth += width + minBuffer;
    }

    return buffer.toString();
  }
}

class ColumnDefinition {
  final String name;
  final Func1<dynamic, String> _mapper;

  ColumnDefinition(this.name, this._mapper) {
    requireArgumentNotNullOrEmpty(name, 'name');
    requireArgumentNotNull(_mapper, '_mapper');
  }
}
