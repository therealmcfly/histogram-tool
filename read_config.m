function cfg = read_config(filepath)
%READ_CONFIG Parse a key = value config file into a struct.
%   Lines starting with # are comments. Blank lines are ignored.
%   Numeric values are converted automatically; otherwise stored as strings.

    text = fileread(filepath);
    lines = strsplit(text, {'\r\n','\n','\r'});
    cfg = struct();

    for i = 1:numel(lines)
        line = strtrim(lines{i});
        if isempty(line) || line(1) == '#'
            continue;
        end
        parts = strsplit(line, '=', 'CollapseDelimiters', false);
        if numel(parts) ~= 2
            continue;
        end
        key = strtrim(parts{1});
        val = strtrim(parts{2});

        num = str2double(val);
        if ~isnan(num)
            cfg.(key) = num;
        else
            cfg.(key) = val;
        end
    end
end
