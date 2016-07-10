;;; xah-css-mode.el --- Major mode for editing CSS code.

;; Copyright © 2013-2015 by Xah Lee

;; Author: Xah Lee ( http://xahlee.org/ )
;; Version: 1.5.6
;; Created: 18 April 2013
;; Keywords: languages, convenience, css, color
;; Homepage:  http://ergoemacs.org/emacs/xah-css-mode.html

;; This file is not part of GNU Emacs.

;;; License:

;; You can redistribute this program and/or modify it under the terms of the GNU General Public License version 2.

;;; Commentary:

;; Major mode for editing CSS code. Alternative to GNU emacs's builtin `css-mode'.

;; Features:

;; • All CSS keywords are colored, and only CSS words (including CSS3). For example, the xyz in 「div.xyz {font-size:1.5rem}」, is not colored. This means, if you have a typo, you'll know. You can easily tell which part of text is CSS, which part came from HTML user defined things, such as class name, id, and values.

;; • Keyword completion, with ido-mode interface. Press Tab key to complete. All CSS words are supported: {html5 tags, property names, property value keywords, units, colors, pseudo selectors words, “at keywords”, …}.

;; • Syntax coloring of hexadecimal color format #rrggbb , #rgb , and HSL Color format hsl(0,68%,42%).

;; • Call `xah-css-hex-to-hsl-color' to convert #rrggbb color format under cursor to HSL Color format.

;; • Call `xah-css-compact-css-region' to compact region.

;; • Call `describe-function' on `xah-css-mode' for detail.

;; • Indentation is currently not supported by design. In works is function that re-format whole blocks of text, as in golang's gofmt.

;; • This package does not depend on any third party libraries.

;;; INSTALL:

;; To manual install,
;; Place the file at ~/.emacs.d/lisp/ . Create the dir if it doesn't exist.
;; Then put the following in ~/.emacs.d/init.el
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; (autoload 'xah-css-mode "xah-css-mode" "css major mode." t)

;;; HISTORY

;; version history no longer kept here.
;; version 2015-01-30 fix a problem with emacs 24.3.1, Debugger entered--Lisp error: (file-error "Cannot open load file" "prog-mode")
;; version 0.3, 2013-05-02 added xah-css-hex-color-to-hsl, and other improvements.
;; version 0.2, 2013-04-22 added xah-css-compact-css-region
;; version 0.1, 2013-04-18 first version


;;; Code:

(require 'color) ; part of emacs 24.3
(require 'newcomment) ; part of emacs

(defvar xah-css-mode-hook nil "Standard hook for `xah-css-mode'")



(defun xah-css-insert-random-color-hsl ()
  "Insert a random color string of CSS HSL format.
Sample output: hsl(100,24%,82%);
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2015-06-11"
  (interactive)
  (insert (format "hsl(%d,%d%%,%d%%);" (random 360) (random 100) (random 100))))

(defun xah-css-hex-color-to-hsl ()
  "Convert color spec under cursor from “#rrggbb” to CSS HSL format.
 ⁖ #ffefd5 ⇒ hsl(37,100%,91%)
URL `http://ergoemacs.org/emacs/elisp_convert_rgb_hsl_color.html'
Version 2015-06-11"
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'word))
         (p1 (car bds))
         (p2 (cdr bds))
         (currentWord (buffer-substring-no-properties p1 p2)))
    (if (string-match "[a-fA-F0-9]\\{6\\}" currentWord)
        (progn
          (delete-region p1 p2 )
          (if (looking-back "#") (delete-char -1))
          (insert (xah-css-hex-to-hsl-color currentWord )))
      (progn
        (user-error "The current word 「%s」 is not of the form #rrggbb." currentWord)))))

(defun xah-css-hex-to-hsl-color (φhex-str)
  "Convert φhex-str color to CSS HSL format.
Return a string. ⁖  \"#ffefd5\" ⇒ \"hsl(37,100%,91%)\"
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2015-06-11"
  (let* (
         (colorVec (xah-css-convert-color-hex-to-vec φhex-str))
         (xR (elt colorVec 0))
         (xG (elt colorVec 1))
         (xB (elt colorVec 2))
         (hsl (color-rgb-to-hsl xR xG xB))
         (xH (elt hsl 0))
         (xS (elt hsl 1))
         (xL (elt hsl 2)))
    (format "hsl(%d,%d%%,%d%%)" (* xH 360) (* xS 100) (* xL 100))))

(defun xah-css-convert-color-hex-to-vec (φhexcolor)
  "Convert φhexcolor from “\"rrggbb\"” string to a elisp vector [r g b], where the values are from 0 to 1.
Example:
 (xah-css-convert-color-hex-to-vec \"00ffcc\") ⇒ [0.0 1.0 0.8]

Note: The input string must NOT start with “#”. If so, the return value is nil.
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2015-06-11"
  (vector
   (xah-css-normalize-number-scale (string-to-number (substring φhexcolor 0 2) 16) 255)
   (xah-css-normalize-number-scale (string-to-number (substring φhexcolor 2 4) 16) 255)
   (xah-css-normalize-number-scale (string-to-number (substring φhexcolor 4) 16) 255)))

(defun xah-css-normalize-number-scale (φval φrange-max)
  "scale φval from range [0, φrange-max] to [0, 1]
The arguments can be int or float.
Return value is float.
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2015-06-11"
  (/ (float φval) (float φrange-max)))


;;; functions

(defun xah-css--replace-regexp-pairs-region (φbegin φend φpairs &optional φfixedcase-p φliteral-p)
  "Replace regex string find/replace ΦPAIRS in region.

ΦBEGIN ΦEND are the region boundaries.

ΦPAIRS is
 [[regexStr1 replaceStr1] [regexStr2 replaceStr2] …]
It can be list or vector, for the elements or the entire argument.

The optional arguments ΦFIXEDCASE-P and ΦLITERAL-P is the same as in `replace-match'.

Find strings case sensitivity depends on `case-fold-search'. You can set it locally, like this: (let ((case-fold-search nil)) …)"
  (save-restriction
      (narrow-to-region φbegin φend)
      (mapc
       (lambda (ξx)
         (goto-char (point-min))
         (while (search-forward-regexp (elt ξx 0) (point-max) t)
           (replace-match (elt ξx 1) φfixedcase-p φliteral-p)))
       φpairs)))

(defun xah-css--replace-pairs-region (φbegin φend φpairs)
  "Replace multiple ΦPAIRS of find/replace strings in region ΦBEGIN ΦEND.

ΦPAIRS is a sequence of pairs
 [[findStr1 replaceStr1] [findStr2 replaceStr2] …]
It can be list or vector, for the elements or the entire argument.

Find strings case sensitivity depends on `case-fold-search'. You can set it locally, like this: (let ((case-fold-search nil)) …)

The replacement are literal and case sensitive.

Once a subsring in the buffer is replaced, that part will not change again.  For example, if the buffer content is “abcd”, and the φpairs are a → c and c → d, then, result is “cbdd”, not “dbdd”.

Note: the region's text or any string in ΦPAIRS is assumed to NOT contain any character from Unicode Private Use Area A. That is, U+F0000 to U+FFFFD. And, there are no more than 65534 pairs."
  (let (
        (ξunicodePriveUseA #xf0000)
        (ξi 0)
        (ξtempMapPoints '()))
    (progn
      ;; generate a list of Unicode chars for intermediate replacement. These chars are in  Private Use Area.
      (setq ξi 0)
      (while (< ξi (length φpairs))
        (push (char-to-string (+ ξunicodePriveUseA ξi)) ξtempMapPoints)
        (setq ξi (1+ ξi))))
    (save-excursion
      (save-restriction
        (narrow-to-region φbegin φend)
        (progn
          ;; replace each find string by corresponding item in ξtempMapPoints
          (setq ξi 0)
          (while (< ξi (length φpairs))
            (goto-char (point-min))
            (while (search-forward (elt (elt φpairs ξi) 0) nil t)
              (replace-match (elt ξtempMapPoints ξi) t t))
            (setq ξi (1+ ξi))))
        (progn
          ;; replace each ξtempMapPoints by corresponding replacement string
          (setq ξi 0)
          (while (< ξi (length φpairs))
            (goto-char (point-min))
            (while (search-forward (elt ξtempMapPoints ξi) nil t)
              (replace-match (elt (elt φpairs ξi) 1) t t))
            (setq ξi (1+ ξi))))))))

(defun xah-css-compact-css-region (φbegin φend)
  "Remove unnecessary whitespaces of CSS source code in region.
WARNING: not robust.
URL `http://ergoemacs.org/emacs/elisp_css_compressor.html'
Version 2015-04-29"
  (interactive "r")
  (save-restriction
    (narrow-to-region φbegin φend)
    (xah-css--replace-regexp-pairs-region
     (point-min)
     (point-max)
     '(["  +" " "]))
    (xah-css--replace-pairs-region
     (point-min)
     (point-max)
     '(
       ["\n" " "]
       [" /* " "/*"]
       [" */ " "*/"]
       [" {" "{"]
       ["{ " "{"]
       ["; " ";"]
       [": " ":"]
       [";}" "}"]
       ["}" "}\n"]
       ))))

(defun xah-css-compact-block ()
  "Compact current CSS code block.
A block is surrounded by blank lines.
This command basically replace newline char by space.
Version 2015-06-29"
  (interactive)
  (let (p1 p2)
    (save-excursion
      (if (re-search-backward "\n[ \t]*\n" nil "move")
          (progn (re-search-forward "\n[ \t]*\n")
                 (setq p1 (point)))
        (setq p1 (point)))
      (if (re-search-forward "\n[ \t]*\n" nil "move")
          (progn (re-search-backward "\n[ \t]*\n")
                 (setq p2 (point)))
        (setq p2 (point))))
    (save-restriction
      (narrow-to-region p1 p2)

      (goto-char (point-min))
      (while (search-forward "\n" nil "NOERROR")
        (replace-match " "))

      (goto-char (point-min))
      (while (search-forward-regexp "  +" nil "NOERROR")
        (replace-match " ")))))


(defvar xah-css-html-tag-names nil "List of HTML5 tag names.")
(setq xah-css-html-tag-names

'(
"a" "abbr" "address" "applet" "area" "article" "aside" "audio" "b"
"base" "basefont" "bdi" "bdo" "blockquote" "body" "br" "button"
"canvas" "caption" "cite" "code" "col" "colgroup" "command" "datalist"
"dd" "del" "details" "dfn" "div" "dl" "doctype" "dt" "em" "embed"
"fieldset" "figcaption" "figure" "footer" "form" "h1" "h2" "h3" "h4"
"h5" "h6" "head" "header" "hgroup" "hr" "html" "i" "iframe" "img"
"input" "ins" "kbd" "keygen" "label" "legend" "li" "link"
"main"
 "map" "mark"
"menu" "meta" "meter" "nav" "noscript" "object" "ol" "optgroup"
"option" "output" "p" "param" "pre" "progress" "q" "rp" "rt" "ruby"
"s" "samp" "script" "section" "select" "small" "source" "span"
"strong" "style" "sub" "summary" "sup" "table" "tbody" "td" "textarea"
"tfoot" "th" "thead" "time" "title" "tr" "u" "ul" "var" "video" "wbr"

))

(defvar xah-css-property-names nil "List of CSS property names.")
(setq xah-css-property-names
'(

"align-content"
"align-items"
"align-self"
"animation"
"animation-delay"
"animation-direction"
"animation-duration"
"animation-fill-mode"
"animation-iteration-count"
"animation-name"
"animation-play-state"
"animation-timing-function"
"attr"
"backface-visibility"
"background"
"background-attachment"
"background-clip"
"background-color"
"background-image"
"background-origin"
"background-position"
"background-repeat"
"background-size"
"border"
"border-bottom"
"border-bottom-color"
"border-bottom-left-radius"
"border-bottom-right-radius"
"border-bottom-style"
"border-bottom-width"
"border-collapse"
"border-color"
"border-image"
"border-image-outset"
"border-image-repeat"
"border-image-slice"
"border-image-source"
"border-image-width"
"border-left"
"border-left-color"
"border-left-style"
"border-left-width"
"border-radius"
"border-right"
"border-right-color"
"border-right-style"
"border-right-width"
"border-spacing"
"border-style"
"border-top"
"border-top-color"
"border-top-left-radius"
"border-top-right-radius"
"border-top-style"
"border-top-width"
"border-width"
"bottom"
"bottom"
"box-decoration-break"
"box-shadow"
"box-sizing"
"break-after"
"break-before"
"break-inside"
"clear"
"color"
"content"
"counter-increment"
"counter-reset"
"cursor"
"direction"
"display"
"filter"
"float"
"font"
"font-family"
"font-size"
"font-style"
"font-weight"
"height"
"left"
"letter-spacing"
"line-height"
"list-style"
"list-style-image"
"list-style-type"
"margin"
"margin-bottom"
"margin-left"
"margin-right"
"margin-top"
"max-height"
"max-width"
"min-height"
"min-width"
"opacity"
"orphans"
"overflow"
"padding"
"padding-bottom"
"padding-left"
"padding-right"
"padding-top"
"page-break-after"
"page-break-inside"
"position"
"pre-wrap"
"right"
"tab-size"
"table-layout"
"text-align"
"text-align"
"text-align-last"
"text-combine-horizontal"
"text-decoration"
"text-decoration"
"text-decoration-color"
"text-decoration-line"
"text-decoration-style"
"text-indent"
"text-orientation"
"text-overflow"
"text-rendering"
"text-shadow"
"text-shadow"
"text-transform"
"text-underline-position"
"top"
"top"
"transform"
"transform-origin"
"transform-style"
"transition"
"transition-delay"
"transition-duration"
"transition-property"
"transition-timing-function"
"unicode-bidi"
"vertical-align"
"white-space"
"widows"
"width"
"word-spacing"
"word-wrap"
"z-index"

) )

(defvar xah-css-pseudo-selector-names nil "List of CSS pseudo selector names.")
(setq xah-css-pseudo-selector-names '(
":active"
":after"
":any"
":before"
":checked"
":default"
":dir"
":disabled"
":empty"
":enabled"
":first"
":first-child"
":first-letter"
":first-line"
":first-of-type"
":focus"
":fullscreen"
":hover"
":in-range"
":indeterminate"
":invalid"
":lang"
":last-child"
":last-of-type"
":left"
":link"
":not"
":nth-child"
":nth-last-child"
":nth-last-of-type"
":nth-of-type"
":only-child"
":only-of-type"
":optional"
":out-of-range"
":read-only"
":read-write"
":required"
":right"
":root"
":scope"
":target"
":valid"
":visited"
) )

(defvar xah-css-media-keywords nil "List of CSS xxxxx todo.")
(setq xah-css-media-keywords '(
"@charset"
"@document"
"@font-face"
"@import"
"@keyframes"
"@media"
"@namespace"
"@page"
"@supports"
"@viewport"
"print"
"screen"
"all"
"speech"
"and"
"not"
"only"
) ) ; todo

(defvar xah-css-unit-names nil "List of CSS unite names.")
(setq xah-css-unit-names
 '("px" "pt" "pc" "cm" "mm" "in" "em" "rem" "ex" "%" "deg") )

(defvar xah-css-value-kwds nil "List of CSS value names")
(setq
 xah-css-value-kwds
 '(

"circle"
"ellipse"
"at"
"!important"
"absolute"
"alpha"
"auto"
"avoid"
"block"
"bold"
"both"
"bottom"
"break-word"
"center"
"collapse"
"dashed"
"dotted"
"embed"
"fixed"
"flex"
"flex-start"
"flex-wrap"
"grid"
"help"
"hidden"
"hsl"
"hsla"
"inherit"
"inline"
"inline-block"
"italic"
"large"
"left"
"line-through"
"linear-gradient"
"ltr"
"middle"
"monospace"
"no-repeat"
"none"
"normal"
"nowrap"
"pointer"
"radial-gradient"
"relative"
"rgb"
"rgba"
"right"
"rotate"
"rotate3d"
"rotateX"
"rotateY"
"rotateZ"
"rtl"
"sans-serif"
"scale"
"scale3d"
"scaleX"
"scaleY"
"scaleZ"
"serif"
"skew"
"skewX"
"skewY"
"small"
"smaller"
"solid"
"square"
"static"
"steps"
"table"
"table-caption"
"table-cell"
"table-column"
"table-column-group"
"table-footer-group"
"table-header-group"
"table-row"
"table-row-group"
"thin"
"top"
"translate"
"translate3d"
"translateX"
"translateY"
"translateZ"
"transparent"
"underline"
"url"
"wrap"
"x-large"
"xx-large"

   ) )

(defvar xah-css-color-names nil "List of CSS color names.")
(setq xah-css-color-names

'("aliceblue" "antiquewhite" "aqua" "aquamarine" "azure" "beige"
"bisque" "black" "blanchedalmond" "blue" "blueviolet" "brown"
"burlywood" "cadetblue" "chartreuse" "chocolate" "coral"
"cornflowerblue" "cornsilk" "crimson" "cyan" "darkblue" "darkcyan"
"darkgoldenrod" "darkgray" "darkgreen" "darkgrey" "darkkhaki"
"darkmagenta" "darkolivegreen" "darkorange" "darkorchid" "darkred"
"darksalmon" "darkseagreen" "darkslateblue" "darkslategray"
"darkslategrey" "darkturquoise" "darkviolet" "deeppink" "deepskyblue"
"dimgray" "dimgrey" "dodgerblue" "firebrick" "floralwhite"
"forestgreen" "fuchsia" "gainsboro" "ghostwhite" "gold" "goldenrod"
"gray" "green" "greenyellow" "grey" "honeydew" "hotpink" "indianred"
"indigo" "ivory" "khaki" "lavender" "lavenderblush" "lawngreen"
"lemonchiffon" "lightblue" "lightcoral" "lightcyan"
"lightgoldenrodyellow" "lightgray" "lightgreen" "lightgrey"
"lightpink" "lightsalmon" "lightseagreen" "lightskyblue"
"lightslategray" "lightslategrey" "lightsteelblue" "lightyellow"
"lime" "limegreen" "linen" "magenta" "maroon" "mediumaquamarine"
"mediumblue" "mediumorchid" "mediumpurple" "mediumseagreen"
"mediumslateblue" "mediumspringgreen" "mediumturquoise"
"mediumvioletred" "midnightblue" "mintcream" "mistyrose" "moccasin"
"navajowhite" "navy" "oldlace" "olive" "olivedrab" "orange"
"orangered" "orchid" "palegoldenrod" "palegreen" "paleturquoise"
"palevioletred" "papayawhip" "peachpuff" "peru" "pink" "plum"
"powderblue" "purple" "red" "rosybrown" "royalblue" "saddlebrown"
"salmon" "sandybrown" "seagreen" "seashell" "sienna" "silver"
"skyblue" "slateblue" "slategray" "slategrey" "snow" "springgreen"
"steelblue" "tan" "teal" "thistle" "tomato" "turquoise" "violet"
"wheat" "white" "whitesmoke" "yellow" "yellowgreen") )

(defvar xah-css-all-keywords nil "List of all elisp keywords")
(setq xah-css-all-keywords (append xah-css-html-tag-names
                                     xah-css-color-names
                                     xah-css-property-names
                                     xah-css-pseudo-selector-names
                                     xah-css-media-keywords
                                     xah-css-unit-names
                                     xah-css-value-kwds
                                     ))


;; completion

(defun xah-css-complete-symbol ()
  "Perform keyword completion on current word.
This uses `ido-mode' user interface for completion."
  (interactive)
  (let* (
         (ξbds (bounds-of-thing-at-point 'symbol))
         (ξp1 (car ξbds))
         (ξp2 (cdr ξbds))
         (ξcurrent-sym
          (if  (or (null ξp1) (null ξp2) (equal ξp1 ξp2))
              ""
            (buffer-substring-no-properties ξp1 ξp2)))
         ξresult-sym)
    (when (not ξcurrent-sym) (setq ξcurrent-sym ""))
    (setq ξresult-sym
          (ido-completing-read "" xah-css-all-keywords nil nil ξcurrent-sym ))
    (delete-region ξp1 ξp2)
    (insert ξresult-sym)))


;; syntax table
(defvar xah-css-syntax-table nil "Syntax table for `xah-css-mode'.")
(setq xah-css-syntax-table
      (let ((synTable (make-syntax-table)))

;        (modify-syntax-entry ?0  "." synTable)
;        (modify-syntax-entry ?1  "." synTable)
;        (modify-syntax-entry ?2  "." synTable)
;        (modify-syntax-entry ?3  "." synTable)
;        (modify-syntax-entry ?4  "." synTable)
;        (modify-syntax-entry ?5  "." synTable)
;        (modify-syntax-entry ?6  "." synTable)
;        (modify-syntax-entry ?7  "." synTable)
;        (modify-syntax-entry ?8  "." synTable)
;        (modify-syntax-entry ?9  "." synTable)

        (modify-syntax-entry ?_ "_" synTable)
        (modify-syntax-entry ?: "." synTable)

        (modify-syntax-entry ?- "_" synTable)
        (modify-syntax-entry ?\/ ". 14" synTable) ; /* java style comment*/
        (modify-syntax-entry ?* ". 23" synTable)
        synTable))


;; syntax coloring related

(setq xah-css-font-lock-keywords
      (let (
            (cssPseudoSelectorNames (regexp-opt xah-css-pseudo-selector-names ))
            (htmlTagNames (regexp-opt xah-css-html-tag-names 'symbols))
            (cssPropertieNames (regexp-opt xah-css-property-names 'symbols ))
            (cssValueNames (regexp-opt xah-css-value-kwds 'symbols))
            (cssColorNames (regexp-opt xah-css-color-names 'symbols))
            (cssUnitNames (regexp-opt xah-css-unit-names t))
            (cssMedia (regexp-opt xah-css-media-keywords )))
        `(
          ("#[a-zA-z]+[0-9]*" . font-lock-defaults)
          (,cssPseudoSelectorNames . font-lock-preprocessor-face)
          (,htmlTagNames . font-lock-function-name-face)
          (,cssPropertieNames . font-lock-variable-name-face )
          (,cssValueNames . font-lock-keyword-face)
          (,cssColorNames . font-lock-constant-face)
          (,cssUnitNames . (1 font-lock-type-face))
          (,cssMedia . font-lock-builtin-face)

          ("#[abcdef[:digit:]]\\{6,6\\}" .
           (0 (put-text-property
               (match-beginning 0)
               (match-end 0)
               'face (list :background (match-string-no-properties 0)))))

          ("#[abcdef[:digit:]]\\{3,3\\};" .
           (0 (put-text-property
               (match-beginning 0)
               (match-end 0)
               'face
               (list
                :background
                (let* (
                       (ms (match-string-no-properties 0))
                       (r (substring ms 1 2))
                       (g (substring ms 2 3))
                       (b (substring ms 3 4)))
                  (concat "#" r r g g b b))))))

          ("hsl( *\\([0-9]\\{1,3\\}\\) *, *\\([0-9]\\{1,3\\}\\)% *, *\\([0-9]\\{1,3\\}\\)% *)" .
           (0 (put-text-property
               (+ (match-beginning 0) 3)
               (match-end 0)
               'face
               (list
                :background
                (concat "#"
                        (mapconcat
                         'identity
                         (mapcar
                          (lambda (x) (format "%02x" (round (* x 255))))
                          (color-hsl-to-rgb
                           (/ (string-to-number (match-string-no-properties 1)) 360.0)
                           (/ (string-to-number (match-string-no-properties 2)) 100.0)
                           (/ (string-to-number (match-string-no-properties 3)) 100.0)))
                         "" )) ;  "#00aa00"
                ))))

          ("'[^']+'" . font-lock-string-face))))


;; indent/reformat related

(defun xah-css-complete-or-indent ()
  "Do keyword completion or indent/prettify-format.

If char before point is letters and char after point is whitespace or punctuation, then do completion, except when in string or comment. In these cases, do `xah-css-prettify-root-sexp'."
  (interactive)
  ;; consider the char to the left or right of cursor. Each side is either empty or char.
  ;; there are 4 cases:
  ;; space▮space → do indent
  ;; space▮char → do indent
  ;; char▮space → do completion
  ;; char ▮char → do indent
  (let ( (ξsyntax-state (syntax-ppss)))
    (if (or (nth 3 ξsyntax-state) (nth 4 ξsyntax-state))
        (progn
          (xah-css-prettify-root-sexp))
      (progn (if
                 (and (looking-back "[-_a-zA-Z]")
                      (or (eobp) (looking-at "[\n[:blank:][:punct:]]")))
                 (xah-css-complete-symbol)
               (xah-css-indent-line))))))

(defun xah-css-indent-line ()
  "i do nothing."
  (let ()
    nil))



(defun xah-css-abbrev-enable-function ()
  "Determine whether to expand abbrev.
This is called by emacs abbrev system."
  (let ((ξsyntax-state (syntax-ppss)))
    (if (or (nth 3 ξsyntax-state) (nth 4 ξsyntax-state))
        (progn nil)
      t)))

(setq xah-css-abbrev-table nil)

(define-abbrev-table 'xah-css-abbrev-table
  '(

    ("bgc" "background-color" nil :system t)
    ("rgb" "rgb(▮)" nil :system t)
    ("rgba" "rgba(▮)" nil :system t)
    ("rotate" "rotate(▮9deg)" nil :system t)
    ("rotate3d" "rotate3d(▮)" nil :system t)
    ("rotateX" "rotateX(▮)" nil :system t)
    ("rotateY" "rotateY(▮)" nil :system t)
    ("rotateZ" "rotateZ(▮)" nil :system t)
    ("scale" "scale(▮)" nil :system t)
    ("scale3d" "scale3d(▮)" nil :system t)
    ("scaleX" "scaleX(▮)" nil :system t)
    ("scaleY" "scaleY(▮)" nil :system t)
    ("scaleZ" "scaleZ(▮)" nil :system t)
    ("skew" "skew(▮9deg)" nil :system t)
    ("skewX" "skewX(▮)" nil :system t)
    ("skewY" "skewY(▮)" nil :system t)
    ("steps" "steps(▮)" nil :system t)

    ("translate" "translate(▮px,▮px)" nil :system t)
    ("translate3d" "translate3d(▮)" nil :system t)
    ("translateX" "translateX(▮)" nil :system t)
    ("translateY" "translateY(▮)" nil :system t)
    ("translateZ" "translateZ(▮)" nil :system t)

)

  "abbrev table for `xah-css-mode'"
  ;; :regexp "\\_<\\([_-0-9A-Za-z]+\\)"
  :regexp "\\([_-0-9A-Za-z]+\\)"
  :case-fixed t
  ;; :enable-function 'xah-css-abbrev-enable-function
  )


;; keybinding

(when (string-equal system-type "windows-nt")
  (define-key key-translation-map (kbd "<apps>") (kbd "<menu>")))

(defvar xah-css-key-map nil "Keybinding for `xah-css-mode'")

(progn
  (setq xah-css-key-map (make-sparse-keymap))
  (define-key xah-css-key-map (kbd "TAB") 'xah-css-complete-or-indent)

  (define-prefix-command 'xah-css-single-keys-map)

  ;; todo need to set these to also emacs's conventional major mode keys
  (define-key xah-css-single-keys-map (kbd "r") 'xah-css-insert-random-color-hsl)
  (define-key xah-css-single-keys-map (kbd "c") 'xah-css-hex-color-to-hsl)
  (define-key xah-css-single-keys-map (kbd "p") 'xah-css-compact-css-region)
  (define-key xah-css-single-keys-map (kbd "u") 'xah-css-complete-symbol)
  (define-key xah-css-single-keys-map (kbd "i") 'xah-css-indent-line)

  ;  (define-key xah-css-key-map [remap comment-dwim] 'xah-css-comment-dwim)
  )



;;;###autoload
(defun xah-css-mode ()
  "A major mode for CSS.

URL `http://ergoemacs.org/emacs/xah-css-mode.html'

\\{xah-css-key-map}"
  (interactive)
  (kill-all-local-variables)

  (setq mode-name "ξCSS")
  (setq major-mode 'xah-css-mode)

  (set-syntax-table xah-css-syntax-table)
  (setq font-lock-defaults '((xah-css-font-lock-keywords)))

  (define-key xah-css-key-map
    (if (boundp 'xah-major-mode-lead-key)
        xah-major-mode-lead-key
      (kbd "C-c C-c"))
    xah-css-single-keys-map)

  (use-local-map xah-css-key-map)

  (setq local-abbrev-table xah-css-abbrev-table)
  (setq-local comment-start "/*")
  (setq-local comment-start-skip "/\\*+[ \t]*")
  (setq-local comment-end "*/")
  (setq-local comment-end-skip "[ \t]*\\*+/")

  (run-mode-hooks 'xah-css-mode-hook))

(add-to-list 'auto-mode-alist '("\\.css\\'" . xah-css-mode))

(provide 'xah-css-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; xah-css-mode.el ends here

