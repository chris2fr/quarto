%% quarto-lettre.cls
%% Shared base class for the lettre and compte-rendu Quarto extensions.
%% Usage in a Pandoc template:
%%   \documentclass[<options>]{quarto-lettre}
%%   \QLsetfooter{...}          % optional: set running footer text
%%   \QLsetfirstpageheader{...} % optional: set first-page header content
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{quarto-lettre}[2026/05/22 Quarto lettre/compte-rendu base class]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass{article}

% ── Page geometry ─────────────────────────────────────────────────────────────
\RequirePackage[inner=20mm, outer=20mm, top=5mm, bottom=25mm,
                headheight=15mm, headsep=5mm,
                showframe=false, includehead]{geometry}

% ── Common packages ───────────────────────────────────────────────────────────
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}
\RequirePackage{parskip}
\RequirePackage{graphicx}
\RequirePackage[hidelinks]{hyperref}
\RequirePackage[french]{babel}
\RequirePackage[osf]{libertinus}
\RequirePackage{fontspec}
\RequirePackage[autostyle=true,french=guillemets]{csquotes}
\RequirePackage{enumitem}
\RequirePackage{soul}
\RequirePackage{bookmark}
\RequirePackage{longtable}
\RequirePackage{booktabs}
\RequirePackage{calc}
\RequirePackage{array}
\RequirePackage[table]{xcolor}
\RequirePackage{fancyvrb}
\RequirePackage{framed}
\RequirePackage[export]{adjustbox}
\RequirePackage{fancyhdr}
\RequirePackage{afterpage}
\RequirePackage{titlesec}
\RequirePackage{titletoc}
\RequirePackage{lastpage}

% ── Thin rule between table data rows ───────────────────────────────────────
% Pandoc's longtable output only rules the table edges and the header
% separator (\toprule/\midrule/\bottomrule); there's nothing between body
% rows. Inserted as literal text between rows by base/_filters/tablerule.lua
% (general Markdown tables) and lettre/compte-rendu's own divs.lua
% (definition-list-as-table divs) — not via redefining \\, which fights
% longtable/booktabs' internal alignment bookkeeping badly enough to corrupt
% the table (tried, reverted: broke \bottomrule with "Misplaced \noalign").
% Built on booktabs' \specialrule rather than a raw \hrule: \hrule has no
% notion of the table's column measure and draws at the full \hsize, which is
% wider than an @{}-trimmed table — visibly overshooting both margins.
% \specialrule reuses booktabs' own width-measuring machinery (same as
% \midrule/\bottomrule), so it always matches the table exactly.
% \arrayrulecolor (colortbl, loaded via xcolor's [table] option above) tints
% it without a grouping brace — wrapping \specialrule's own leading \noalign
% in one is exactly what produced the "Misplaced \noalign" above.
\newcommand{\QLrowrule}{\arrayrulecolor{black!60}\specialrule{0.4pt}{2pt}{2pt}\arrayrulecolor{black}}

% ── Fonts ───────────────────────────────────────────────────────────
% \RequirePackage{libertinus} % Libertinus Mono, Libertinus Sans, Libertinus Serif
% \RequirePackage{fourier}
% \RequirePackage{newcent}
% \RequirePackage{charter}
% \RequirePackage{bookman}
% \RequirePackage{avant}
% \RequirePackage{mathpazo}
% \RequirePackage{helvet}
% \RequirePackage{mathptmx}
% \RequirePackage{lmodern}
% \RequirePackage{newpxmath} 
% \RequirePackage{kpfonts}
% \RequirePackage{cochineal}
% \RequirePackage{cabin}
% \RequirePackage{garamondx}
% \RequirePackage{inconsolata}
% \RequirePackage{FiraSans}
% \RequirePackage{roboto}
% \RequirePackage{inter}
% \RequirePackage{MinionPro}
% \RequirePackage{mathastext}
% \RequirePackage{fbb} % Bembo-like fbb
% % \RequirePackage[sfdefault]{plex-sans}
% \RequirePackage[sfdefault,condensed]{plex-sans}
\RequirePackage{plex-sans}
\RequirePackage{plex-serif}
\RequirePackage{plex-mono}
% \RequirePackage{FiraSerif}
% \RequirePackage[sfdefault]{FiraSans}
% \RequirePackage{FiraMono}

\setmainfont{IBM Plex Serif}
\setsansfont{IBM Plex Sans}
\setmonofont{IBM Plex Mono}

% Set by brand_fonts_latex (page.lua) via \IfFontExistsTF when brand.yml
% declares a headings font that's actually available; empty (no-op) otherwise.
% \newcommand{\QLheadingfont}{}
% \newcommand{\QLheadingfont}{\sfdefault}
\newcommand{\QLheadingfont}{\plexsans}
% plex-sans's \defaultfontfeatures{Extension=.otf} is cleared again at the end
% of that package, so it must be repeated here for this direct fontspec call.
\newfontfamily\QLheadingfontmd[Extension=.otf, ItalicFont=IBMPlexSans-MediumItalic]{IBMPlexSans-Medium}
\newfontfamily\QLheadingfontsb[Extension=.otf, ItalicFont=IBMPlexSans-SemiBoldItalic]{IBMPlexSans-SemiBold}

\titleformat{\section} % command
  [block] % shape
  {\centering\normalfont\QLheadingfont\huge} % format
  {} % label
  {0pt} % sep
  {} % {\titlerule\vspace{0.5em}\\} % before-code
  % [] % after-code
\titleformat{\subsection}
  {\normalfont\QLheadingfontsb\Large}{}{0pt}{}
  [\vspace{0.5em}]
\titleformat{\subsubsection}
  {\normalfont\QLheadingfontmd\large}{}{0pt}{}
  [\vspace{0.25em}]
\titleformat{\paragraph}
  {\normalfont\QLheadingfontmd\large\itshape}{}{0pt}{} % flushright
\titleformat{\subparagraph}
  {\normalfont\QLheadingfont\normalsize\bfseries}{}{0pt}{}
\titlespacing*{\section}{0pt}{2cm plus 1cm }{0.75cm}
\titlespacing*{\subsection}{0pt}{1.25cm plus 0.75cm}{0.25cm}
\titlespacing*{\subsubsection}{0pt}{0.6cm}{0.4cm}
\titlespacing*{\paragraph}{0pt}{0.5cm}{0.25cm}
\titlespacing*{\subparagraph}{0pt}{0.4cm}{0.2cm}

% secnumdepth must stay > 0 (unlike a plain \thesection-suppressing 0) so
% \@startsection still \refstepcounter's each heading: at 0 it falls back to
% a bare \stepcounter, which never registers the heading as a hyperref
% anchor, so every \tableofcontents entry (and TOC hyperlink) collapses onto
% the same "Doc-Start" target instead of its own section — invisible on a
% one-page letter, glaringly wrong once headings span several pages. Numbers
% themselves stay hidden via the empty titleformat labels above; secnumdepth
% would otherwise also make titlesec prefix TOC lines with \numberline{N},
% which \renewcommand{\numberline} below strips back out. 5 levels deep
% (down to \subparagraph, ##### in Markdown — the deepest heading LaTeX has
% a sectioning command for) — matches tocdepth below.
\setcounter{secnumdepth}{5}
\setcounter{tocdepth}{5}
\renewcommand{\numberline}[1]{}
% {{< toc >}} (../../base/_filters/toc.lua) can appear more than once —
% plain \tableofcontents can't: it re-opens \jobname.toc for writing right
% after reading it, so a second call in the same run reads back a file
% nothing has been written into yet at that point, and prints empty.
% titletoc's named lists sidestep this: \startcontents opens the "toc" list
% once for the whole document, and \QLtoc can then print it back any number
% of times, each independently scoped to its own depth.
\AtBeginDocument{\startcontents[toc]}
\newcommand{\QLtoc}[1][5]{\printcontents[toc]{}{1}{\setcounter{tocdepth}{#1}}}
% Same leak, for the running head (\leftmark/\rightmark, e.g. a project's
% own \fancyhead[C]{...\rightmark} via tex-custom): the kernel's default
% \sectionmark/\subsectionmark also prepend \thesection/\thesubsection once
% secnumdepth > 0, so without this a page header would show "0.1 Heading"
% (0 since a subsection with no preceding \section leaves \thesection at its
% initial value) instead of just "Heading".
% \renewcommand{\sectionmark}[1]{\markright{#1}}
% \renewcommand{\subsectionmark}[1]{\markboth{#1}{}}
\renewcommand{\sectionmark}[1]{\markboth{#1}{}}
\renewcommand{\subsectionmark}[1]{\markright{#1}}
% \renewcommand{\subsectionmark}[1]{\markright{\thesubsection.\ #1}}
\newcounter{none}
\providecommand{\tightlist}{\setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}

\MakeOuterQuote{"}

% ── Configurable header / footer (set these before \begin{document}) ──────────
\newcommand{\@QLfooter}{}
\newcommand{\@QLfirstpageheader}{}
\newcommand{\QLsetfooter}[1]{\renewcommand{\@QLfooter}{#1}}
\newcommand{\QLsetfirstpageheader}[1]{\renewcommand{\@QLfirstpageheader}{#1}}

% ── Page styles ───────────────────────────────────────────────────────────────
% \rightmark comes back empty on pages before the first \subsection of a
% \section (\sectionmark's \markboth{#1}{} clears it), so \QLpageheading
% shows just the section title there; once a \subsection has fired,
% \subsectionmark's \markright overwrites \rightmark and the header grows to
% "section — subsection". \edef+\ifx\@empty (rather than testing \rightmark
% directly) is needed because \rightmark is itself a macro that must be
% expanded before comparison.
\newcommand{\QLpageheading}{%
  \edef\QLrightmark{\rightmark}%
  \ifx\QLrightmark\@empty
    \leftmark
  \else
    % \leftmark\ --- \rightmark
    \rightmark
  \fi
}
\renewcommand{\headrulewidth}{0pt}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[C]{\textit\QLpageheading}
\fancyfoot[C]{\small\thepage\ / \pageref{LastPage}\\\@QLfooter}
% \fancyfoot[C]{\small\thepage\\\@QLfooter}

\fancypagestyle{firstpage}{%
  \fancyhf{}
  \renewcommand{\headrulewidth}{0pt}
  \fancyhead[C]{\@QLfirstpageheader}
  \fancyfoot[C]{\small\@QLfooter}
}

% ── Pandoc image bounding ─────────────────────────────────────────────────────
\makeatletter
\newsavebox\pandoc@box
\newcommand*\pandocbounded[1]{%
  \sbox\pandoc@box{#1}%
  \Gscale@div\@tempa{\textheight}{\dimexpr\ht\pandoc@box+\dp\pandoc@box\relax}%
  \Gscale@div\@tempb{\linewidth}{\wd\pandoc@box}%
  \ifdim\@tempb\p@<\@tempa\p@\let\@tempa\@tempb\fi%
  \ifdim\@tempa\p@<\p@\scalebox{\@tempa}{\usebox\pandoc@box}%
  \else\usebox{\pandoc@box}%
  \fi%
}
\makeatother

% ── Syntax highlighting ───────────────────────────────────────────────────────
\DefineVerbatimEnvironment{Highlighting}{Verbatim}{commandchars=\\\{\}}
\definecolor{shadecolor}{RGB}{248,248,248}
\newenvironment{Shaded}{\begin{snugshade}}{\end{snugshade}}
\newcommand{\AlertTok}[1]{\textcolor[rgb]{0.94,0.16,0.16}{#1}}
\newcommand{\AnnotationTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}
\newcommand{\AttributeTok}[1]{\textcolor[rgb]{0.13,0.29,0.53}{#1}}
\newcommand{\BaseNTok}[1]{\textcolor[rgb]{0.00,0.00,0.81}{#1}}
\newcommand{\BuiltInTok}[1]{#1}
\newcommand{\CharTok}[1]{\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\newcommand{\CommentTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}
\newcommand{\CommentVarTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}
\newcommand{\ConstantTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{#1}}
\newcommand{\ControlFlowTok}[1]{\textcolor[rgb]{0.13,0.29,0.53}{\textbf{#1}}}
\newcommand{\DataTypeTok}[1]{\textcolor[rgb]{0.13,0.29,0.53}{#1}}
\newcommand{\DecValTok}[1]{\textcolor[rgb]{0.00,0.00,0.81}{#1}}
\newcommand{\DocumentationTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}
\newcommand{\ErrorTok}[1]{\textcolor[rgb]{0.64,0.00,0.00}{\textbf{#1}}}
\newcommand{\ExtensionTok}[1]{#1}
\newcommand{\FloatTok}[1]{\textcolor[rgb]{0.00,0.00,0.81}{#1}}
\newcommand{\FunctionTok}[1]{\textcolor[rgb]{0.13,0.29,0.53}{\textbf{#1}}}
\newcommand{\ImportTok}[1]{#1}
\newcommand{\InformationTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}
\newcommand{\KeywordTok}[1]{\textcolor[rgb]{0.13,0.29,0.53}{\textbf{#1}}}
\newcommand{\NormalTok}[1]{#1}
\newcommand{\OperatorTok}[1]{\textcolor[rgb]{0.81,0.36,0.00}{\textbf{#1}}}
\newcommand{\OtherTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{#1}}
\newcommand{\PreprocessorTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}
\newcommand{\RegionMarkerTok}[1]{#1}
\newcommand{\SpecialCharTok}[1]{\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\newcommand{\SpecialStringTok}[1]{\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\newcommand{\StringTok}[1]{\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\newcommand{\VariableTok}[1]{\textcolor[rgb]{0.00,0.00,0.00}{#1}}
\newcommand{\VerbatimStringTok}[1]{\textcolor[rgb]{0.31,0.60,0.02}{#1}}
\newcommand{\WarningTok}[1]{\textcolor[rgb]{0.56,0.35,0.01}{\textbf{\textit{#1}}}}

% ── Bibliography (CSL) ────────────────────────────────────────────────────────
\NewDocumentCommand\citeproctext{}{}
\NewDocumentCommand\citeproc{mm}{%
  \begingroup\def\citeproctext{#2}\cite{#1}\endgroup}
\makeatletter
\let\@cite@ofmt\@firstofone
\def\@biblabel#1{}
\def\@cite#1#2{{#1\if@tempswa , #2\fi}}
\makeatother
\newlength{\cslhangindent}
\setlength{\cslhangindent}{1.5em}
\newlength{\csllabelwidth}
\setlength{\csllabelwidth}{3em}
\newlength{\cslentryspacingunit}
\setlength{\cslentryspacingunit}{\parskip}
\newenvironment{CSLReferences}[2]
 {\begin{list}{}{%
  \setlength{\itemindent}{0pt}
  \setlength{\leftmargin}{0pt}
  \setlength{\parsep}{0pt}
  \ifodd #1
  \setlength{\leftmargin}{\cslhangindent}
  \setlength{\itemindent}{-1\cslhangindent}
  \fi
  \setlength{\itemsep}{#2\cslentryspacingunit}}}
 {\end{list}}
\newcommand{\CSLBlock}[1]{\hfill\break\parbox[t]{\linewidth}{\strut\ignorespaces#1\strut}}
\newcommand{\CSLLeftMargin}[1]{\parbox[t]{\csllabelwidth}{\strut#1\strut}}
\newcommand{\CSLRightInline}[1]{\parbox[t]{\linewidth - \csllabelwidth}{\strut#1\strut}}
\newcommand{\CSLIndent}[1]{\hspace{\cslhangindent}#1}
