"=============================================================================
" $Id$
" File:		ftplugin/c/c_brackets.vim                                {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	2.2.0
" Created:	26th May 2004
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
" 	c-ftplugin that defines the default preferences regarding the
" 	bracketing mappings we want to use.
" 
"------------------------------------------------------------------------
" Installation:	
" 	This particular file is meant to be into {rtp}/after/ftplugin/c/
" 	In order to override these default definitions, copy this file into a
" 	directory that comes before the {rtp}/after/ftplugin/c/ you choosed --
" 	typically $HOME/.vim/ftplugin/c/ (:h 'rtp').
" 	Then, replace the calls to :Brackets
"
" History:	
"	v2.1.0  29th Jan 2014
"	        Mappings factorized into plugin/common_brackets.vim
"	v2.0.1  14th Aug 2013
"	        { now doesn't insert a new line anymore. but just "{}".
"	        Hitting <cr> while the cursor in between "{}", will add an
"	        extra line between the cursor and the closing bracket.
"	v2.0.0  11th Apr 2012
"	        License GPLv3 w/ extension
"	v1.0.0	19th Mar 2008
"		Exploit the new kernel from map-tools v1.0.0 
"	v0.5    26th Sep 2007
"		No more jump on close
"	v0.4    25th May 2006
"	        Bug fix regarding the insertion of < in UTF-8
"	v0.3	31st Jan 2005
"		�<� expands into �<>!mark!� after: �#include�, and after some
"		C++ keywords: �reinterpret_cast�, �static_cast�, �const_cast�,
"		�dynamic_cast�, �lexical_cast� (from boost), �template� and
"		�typename[^<]*�
" TODO:		
" }}}1
"=============================================================================


"=============================================================================
" Buffer-local Definitions {{{1
" Avoid buffer reinclusion {{{2
if exists('b:loaded_ftplug_c_brackets') && !exists('g:force_reload_ftplug_c_brackets')
  finish
endif
let s:k_version = 220
let b:loaded_ftplug_c_brackets = s:k_version
 
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Brackets & all {{{2
" ------------------------------------------------------------------------
if !exists(':Brackets')
  runtime plugin/common_brackets.vim
endif
" It seems that function() does not load anything ...
if !exists('lh#cpp#brackets#lt')
  runtime autoload/lh/cpp/brackets.vim
endif

if exists(':Brackets')
  let b:cb_jump_on_close = 1
  " Re-run brackets() in order to update the mappings regarding the different
  " options.
  :Brackets < > -open=function('lh#cpp#brackets#lt') -visual=0
  :Brackets { } -visual=1 -insert=0 -nl -trigger=<localleader>{
  "}
  :Brackets { } -visual=0 -insert=1 -open=function('lh#cpp#brackets#close_curly')

  " Doxygen surround action
  :Brackets <tt> </tt> -visual=1 -insert=0 -trigger=<localleader>tt
  " :Brackets /* */ -visual=0
  " :Brackets /** */ -visual=0 -trigger=/!
  "
  " eclipse (?) behaviour (placeholders are facultatives)
  " '(foo|��)��' + ';' --> '("foo");|'
  " '("foo|"��)��' + ';' --> '("foo");|'
  " '(((foo|)��)��)' + ';' --> '(((foo)));|'
  if lh#dev#option#get('semicolon_closes_bracket', &ft, 1)
    call lh#brackets#define_imap(';',
          \ [{'condition': 'getline(".")[col(".")-1:-1]=~"^\"\\=\\(".Marker_Txt(".\\{-}")."\\)\\=)\\+"',
          \   'action': 's:JumpOverAllClose(")", ";")'},
          \  {'condition': 'getline(".")[col(".")-1:-1]=~"^;"',
          \   'action': 's:JumpOverAllClose(";", "")'}],
          \1)
    " Override default definition from lh-brackets to take care of semi-colon
    call lh#brackets#define_imap('<bs>',
          \ [{ 'condition': 'getline(".")[:col(".")-2]=~".*\"\\s*)\\+;$"',
          \   'action': 'Cpp_MoveSemicolBackToStringContext()'},
          \  { 'condition': 'lh#brackets#_match_any_bracket_pair()',
          \   'action': 'lh#brackets#_delete_empty_bracket_pair()'}],
          \ 1,
          \ '\<bs\>'
          \ )
  endif
endif
" }}}1
"=============================================================================
" Global Definitions {{{1
" Avoid global reinclusion {{{2
if exists('g:loaded_ftplug_c_brackets')
      \ && !exists('g:force_reload_ftplug_c_brackets')
  let s:cpo_save=&cpo
  set cpo&vim
  finish
endif
let g:loaded_ftplug_c_brackets = s:k_version
"------------------------------------------------------------------------
" Global functions {{{2
" TODO: use <SNR> function
function! Cpp_MoveSemicolBackToStringContext()
  " It seem c-o leaves the insert mode for good. Thats odd.
  " BUG? -> return "\<bs>\<c-o>F\";"
  " Let's do n-<left> instead
  let l=getline('.')[:col(".")-3]
  let end = matchstr(l, '"\s*)\+$')
  let lend= lh#encoding#strlen(end)
  let move = repeat("\<left>", lend)
  return "\<bs>".move.";"
endfunction

"=============================================================================

" }}}1
"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
