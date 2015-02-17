#!/usr/bin/env texlua

-- Build script for interchar package

maindir = "."
tempdir = "./temp/"

function help()
  print ""
  print " icbuild cleanup   - clean up current directory "
  print " icbuild package   - create CTAN-ready package  "
  print " icbuild unicode   - regenerate char class data "
  print ""
end

function main(target)
  if target == "cleanup" then
    print("cleanup")
  elseif target == "package" then
    package()
  elseif target == "unicode" then
    unicode()
  else
    help()
  end
end

function package()
  local dosbat = [[
    xelatex interchar
    xelatex interchar
    xelatex interchartest
    xelatex interchardemo1
    if not exist temp\tex\xelatex\interchar md temp\tex\xelatex\interchar
    copy /y interchar.sty temp\tex\xelatex\interchar
    if not exist temp\doc\xelatex\interchar md temp\doc\xelatex\interchar
    copy /y interchar.tex temp\doc\xelatex\interchar
    copy /y interchar.pdf temp\doc\xelatex\interchar
    copy /y interchartest.tex temp\doc\xelatex\interchar
    copy /y interchartest.pdf temp\doc\xelatex\interchar
    copy /y interchardemo1.tex temp\doc\xelatex\interchar
    copy /y interchardemo1.pdf temp\doc\xelatex\interchar
    copy /y README temp\doc\xelatex\interchar
    if not exist temp\interchar md temp\interchar
    copy /y interchar.sty temp\interchar
    copy /y interchar.tex temp\interchar
    copy /y interchar.pdf temp\interchar
    copy /y README temp\interchar
    if exist temp\interchar.tds.zip del temp\interchar.tds.zip
    if exist temp\interchar.zip del temp\interchar.zip
    cd temp && zip -r -X -ll interchar.tds.zip doc tex
    cd temp && zip -r -X -ll interchar.zip interchar.tds.zip interchar
  ]]
  --- temp\unzip.exe -Z -v temp\interchar.tds.zip
  for line in string.gmatch(dosbat, "%s*([^\n]*)%s*\n") do
    os.execute(line)
  end
end

function unicode()
  io.input(tempdir .. "unicode-letters.tex")
  io.output(tempdir .. "interchar-class.txt")

  -- These variables should be global
  class0, class1, class2, class3, class256 = {}, {}, {}, {}, {}
  from0, from1, from2, from3, from256 = nil, nil, nil, nil, nil
  to0, to1, to2, to3, to256 = nil, nil, nil, nil, nil
  local classlist = {0, 1, 2, 3, 256}

  local function storedata(c, from, to)
    local class = _G["class" .. c]
    local function store(from, to)
      local fromto = from
      if (from ~= to) then fromto = from .. "-" .. to end
      table.insert(class, fromto)
    end
    -- first item
    if ( _G["from" .. c] == nil ) then
      _G["from" .. c] = from
      _G["to" .. c] = to
    -- last item
    elseif (from == nil) then
      store(_G["from" .. c], _G["to" .. c])
    -- middle item, adjacent
    elseif ( tonumber(_G["to" .. c], 16) + 1 == tonumber(from, 16)) then
      _G["to" .. c] = to
    else
    -- middle item, not adjacent
      store(_G["from" .. c], _G["to" .. c])
      _G["from" .. c] = from
      _G["to" .. c] = to
    end
  end

  local function matchdata()
    local pattern = "\\(%u%u) (%w*) (%w*)\n"
    local index0 = 1
    for n1, n2, n3 in string.gmatch(io.read("*all"), pattern) do
      -- class c > 0
      if ( n1 == "ID" ) then
        storedata(1, n2, n3)
      elseif ( n1 == "OP" ) then
        storedata(2, n2, n3)
      elseif ( n1 == "CL" or n1 == "EX" or n1 == "IS" or n1 == "NS" ) then
        storedata(3, n2, n3)
      elseif ( n1 == "CM" ) then
        storedata(256, n2, n3)
      else
        print("ERROR!")
      end
      -- class 0
      local r0, s0 = tonumber(index0, 16), tonumber(n2, 16) - 1
      if ( r0 <= s0) then
        storedata(0, index0, string.format("%X", s0))
      end
      index0 = string.format("%X", tonumber(n3, 16) + 1)
    end
    for _, v in ipairs(classlist) do
      storedata(v, nil, nil)
    end
  end

  local function writedata()
    for _, v in ipairs(classlist) do
      local class = _G["class" .. v]
      local str = "\\clist_set:cn { l_interchar_default_chars_" .. v ..  "_clist }\n"
      str = str .. "  {\n    " .. table.concat(class, ", ") .. "\n  }\n"
      io.write(str)
    end
  end

  matchdata()
  writedata()
end

main(arg[1])
