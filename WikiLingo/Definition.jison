//phpOption parserClass:WikiLingo_Definition
//phpOption fileName:Definition.php
//phpOption usingZend:true

//Lexical Grammer
%lex

PLUGIN_ID   					[A-Z]+
INLINE_PLUGIN_ID				[a-z]+
VARIABLE_NAME                   ([0-9A-Za-z ]{3,})
SYNTAX_CHARS                    [{}\n_\^:\~'-|=\(\)\[\]*#+%<≤]
LINE_CONTENT                    (.?)
LINES_CONTENT                   (.|\n)+
LINE_END                        (\n)
BLOCK_START                     ([\!*#+;])
WIKI_LINK_TYPE                  (([a-z0-9-]+))
CAPITOL_WORD                    ([A-Z]{1,}[a-z_\-\x80-\xFF]{1,}){2,}

%s np pp pluginStart plugin inlinePlugin line block bold box center code color italic unlink link strike table titleBar underscore wikiLink

%%
<np><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

		return 'EOF';
	%}
<np>"~/np~"
	%{
	    //js
		    if (parser.npStack != true) return 'CONTENT';
		    lexer.popState();
		    parser.npStack = false;
		    yytext = parser.noParse(yytext);

        /*php
		    if ($this->npStack != true) return 'CONTENT';
		    $this->popState();
		    $this->npStack = false;
		    $yytext = $this->noParse($yytext);
        */

		return 'NO_PARSE_END';
	%}
"~np~"
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';
		    lexer.begin('np');
		    parser.npStack = true;

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('np');
		    $this->npStack = true;
        */

		return 'NO_PARSE_START';
	%}


<pp><<EOF>>
	%{
	    //js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<pp>"~/pp~"
	%{
	    //js
		    if (parser.ppStack != true) return 'CONTENT';
		    lexer.popState();
		    parser.ppStack = false;
		    yytext = parser.preFormattedText(yytext);

        /*php
		    if ($this->ppStack != true) return 'CONTENT';
		    $this->popState();
		    $this->ppStack = false;
		    $yytext = $this->preFormattedText($yytext);
        */

		return 'PREFORMATTED_TEXT_END';
	%}
"~pp~"
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';
		    lexer.begin('pp');
		    parser.ppStack = true;

        /*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('pp');
		    $this->ppStack = true;
        */

		return 'PREFORMATTED_TEXT_START';
	%}


"~tc~"{LINES_CONTENT}"~/tc~"                    return 'COMMENT';


[%][%]{VARIABLE_NAME}[%][%]
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';

        /*php
            if ($this->isContent()) return 'CONTENT';
        */

		return 'DOUBLE_DYNAMIC_VAR';
	%}
[%]{VARIABLE_NAME}[%]
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';

        /*php
            if ($this->isContent()) return 'CONTENT';
        */

		return 'SINGLE_DYNAMIC_VAR';
	%}

"{{"{VARIABLE_NAME}([|]{VARIABLE_NAME})?"}}"
	%{
	    //js
            if (parser.isContent(['linkStack'])) return 'CONTENT';

        /*php
            if ($this->isContent(array('linkStack'))) return 'CONTENT';
        */

        return 'ARGUMENT_VAR';
    %}

"{rm}"                                      return 'CHAR';
"{ELSE}"						            return 'CONTENT';//For now let individual plugins handle else
{LINE_END}("{r2l}"|"{l2r}")
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';
            lexer.begin('block');

        /*php
            if ($this->isContent()) return 'CONTENT';
            $this->begin('block');
        */

        return 'BLOCK_START';
	%}
<inlinePlugin>"}"
	%{
		/*php
			$this->popState();
			return 'INLINE_PLUGIN_PARAMETERS';
		*/
	%}
"{"{INLINE_PLUGIN_ID}
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';
		    yytext = parser.inlinePlugin(yytext);

        /*php
            $this->begin('inlinePlugin');
		*/

		return 'INLINE_PLUGIN_START';
	%}

<pluginStart>.*?")}"
    %{
        /*php
            $this->popState();
            $this->begin('plugin');
            return 'PLUGIN_PARAMETERS';
        */
    %}

"{"{PLUGIN_ID}"("
	%{
	    //js
            if (parser.npStack || parser.ppStack) return 'CONTENT';

            lexer.begin('pluginStart');
            yy.pluginStack = parser.stackPlugin(yytext, yy.pluginStack);

            if (parser.size(yy.pluginStack) == 1) {
                return 'PLUGIN_START';
            }

            return 'CONTENT';

        /*php
		    $this->begin('pluginStart');
		    $this->stackPlugin($yytext);
	        return 'PLUGIN_START';
		*/
	%}
<plugin><<EOF>>
	%{
	    //js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<plugin>"{"{PLUGIN_ID}"}"
	%{
	    //js
            var plugin = yy.pluginStack[yy.pluginStack.length - 1];
            if (('{' + plugin.name + '}') == yytext) {
                lexer.popState();
                if (yy.pluginStack) {
                    if (
                        parser.size(yy.pluginStack) > 0 &&
                        parser.substring(yytext, 1, -1) == yy.pluginStack[parser.size(yy.pluginStack) - 1].name
                    ) {
                        if (parser.size(yy.pluginStack) == 1) {
                            yytext = yy.pluginStack[parser.size(yy.pluginStack) - 1];
                            yy.pluginStack = parser.pop(yy.pluginStack);
                            return 'PLUGIN_END';
                        } else {
                            yy.pluginStack = parser.pop(yy.pluginStack);
                            return 'CONTENT';
                        }
                    }
                }
            }

		/*php
            $name = end($this->pluginStack);
            if (substr($yytext, 1, -1) == $name && $this->pluginStackCount > 0) {
				$this->popState();
				$this->pluginStackCount--;
				array_pop($this->pluginStack);
				return 'PLUGIN_END';
            }
		*/

		return 'CONTENT';
	%}



<block><<EOF>>
	%{
	    //js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<block>(?={LINE_END})
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

        /*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */


		return 'BLOCK_END';
	%}
{LINE_END}(?={BLOCK_START})
	%{
    	//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('block');

        /*php
            if ($this->isContent()) return 'CONTENT';
            $this->begin('block');
        */

        return 'BLOCK_START';
	%}
{LINE_END}
	%{
		//js
		    if (parser.isContent() || parser.tableStack) return 'CONTENT';

		/*php
		    if ($this->isContent() || !empty($this->tableStack)) return 'CONTENT';
        */

		return 'LINE_END';
	%}


"---"
	%{
		//js
	    	if (parser.isContent()) return 'CONTENT';

        /*php
            if ($this->isContent()) return 'CONTENT';
        */

        return 'HORIZONTAL_BAR';
	%}
"%%%"
	%{
		//js
		    if (parser.isContent()) return 'CONTENT';

        /*php
            if ($this->isContent()) return 'CONTENT';
        */

        return 'FORCED_LINE_END';
	%}



<bold><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<bold>[_][_]
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'BOLD_END';
	%}
[_][_]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('bold');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('bold');
        */

		return 'BOLD_START';
	%}


<box><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<box>[\^]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'BOX_END';
	%}
[\^]
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('box');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('box');
        */


		return 'BOX_START';
	%}


<center><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<center>[:][:]
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */


		return 'CENTER_END';
	%}
[:][:]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('center');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('center');
        */

		return 'CENTER_START';
	%}



<code><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<code>"+-"
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'CODE_END';
	%}
"-+"
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('code');


		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('code');
        */

		return 'CODE_START';
	%}



<color><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<color>[\~][\~]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'COLOR_END';
	%}
[\~][\~]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('color');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('color');
        */

		return 'COLOR_START';
	%}



<italic><<EOF>>
	%{
	    //js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<italic>['][']
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'ITALIC_END';
	%}
['][']
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('italic');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('italic');
		*/

		return 'ITALIC_START';
	%}


<unlink><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<unlink>("@np"|"]]"|"]")
	%{
	    //js
            if (parser.isContent(['linkStack'])) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent(array('linkStack'))) return 'CONTENT';
		    $this->popState();
        */

		return 'UNLINK_END';
	%}
"[["
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('unlink');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('unlink');
        */

		return 'UNLINK_START';
	%}



<link><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

		/*php
		    $this->conditionStackCount = 0;
		    $this->conditionStack = array();
        */

		return 'EOF';
	%}
<link>"]"
	%{
		//js
            if (parser.isContent(['linkStack'])) return 'CONTENT';
            parser.linkStack = false;
            lexer.popState();

		/*php
		    if ($this->isContent(array('linkStack'))) return 'CONTENT';
            $this->linkStack = false;
            $this->popState();
        */

		return 'LINK_END';
	%}
"["(?![ ])
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            parser.linkStack = true;
            lexer.begin('link');
            yytext = 'external';

		/*php
		    if ($this->isContent()) return 'CONTENT';
            $this->linkStack = true;
            $this->begin('link');
            $yytext = 'external';
        */

		return 'LINK_START';
	%}


<strike><<EOF>>
	%{
	    //js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<strike>[-][-]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'STRIKE_END';
	%}
[-][-](?![ ]|<<EOF>>)
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('strike');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('strike');
        */

		return 'STRIKE_START';
	%}
[ ][-][-][ ]
	%{
        return 'DOUBLE_DASH';
	%}

<table><<EOF>>
	%{
	    //js
		    lexer.conditionStack = [];

		/*php
		    $this->conditionStackCount = 0;
		    $this->conditionStack = array();
        */

		return 'EOF';
	%}
<table>[|][|]
	%{
		//js
		    if (parser.isContent()) return 'CONTENT';
		    lexer.popState();
            parser.tableStack.pop();

		/*php
		    if ($this->isContent()) return 'CONTENT';
            $this->popState();
            array_pop($this->tableStack);
		*/

		return 'TABLE_END';
	%}
[|][|]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('table');
            parser.tableStack.push(true);

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('table');
		    $this->tableStack[] = true;
        */

		return 'TABLE_START';
	%}


<titleBar><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

        /*php
            $this->conditionStackCount = 0;
            $this->conditionStack = array();
        */

        return 'EOF';
	%}
<titleBar>[=][-]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'TITLE_BAR_END';
	%}
[-][=]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('titleBar');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->begin('titleBar');
		*/

		return 'TITLE_BAR_START';
	%}



<underscore><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

		/*php
		    $this->conditionStackCount = 0;
		    $this->conditionStack = array();
        */

		return 'EOF';
	%}
<underscore>[=][=][=]
	%{
	    //js
            if (parser.isContent()) return 'CONTENT';
            lexer.popState();

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->popState();
        */

		return 'UNDERSCORE_END';
	%}
[=][=][=]
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            lexer.begin('underscore');

		/*php
		    if ($this->isContent()) return 'CONTENT';
    		$this->begin('underscore');
        */

		return 'UNDERSCORE_START';
	%}


<wikiLink><<EOF>>
	%{
		//js
		    lexer.conditionStack = [];

		/*php
		    $this->conditionStackCount = 0;
		    $this->conditionStack = array();
        */

		return 'EOF';
	%}
<wikiLink>"))"|"(("
	%{
		//js
		    if (parser.isContent(['linkStack'])) return 'CONTENT';
		    parser.linkStack = false;
		    lexer.popState();

		/*php
		    if ($this->isContent(array('linkStack'))) return 'CONTENT';
		    $this->linkStack = false;
		    $this->popState();
		*/

		return 'WIKI_LINK_END';
	%}
"(("
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            parser.linkStack = true;
            lexer.begin('wikiLink');

		/*php
		    if ($this->isContent()) return 'CONTENT';
            $this->linkStack = true;
            $this->begin('wikiLink');
            $yytext = array('type' => 'wiki', 'syntax' => $yytext);
        */

		return 'WIKI_LINK_START';
	%}
"))"
	%{
		//js
            if (parser.isContent()) return 'CONTENT';
            parser.linkStack = true;
            lexer.begin('wikiLink');

		/*php
		    if ($this->isContent()) return 'CONTENT';
		    $this->linkStack = true;
		    $this->begin('wikiLink');
		    $yytext = array('type' => 'np', 'syntax' => $yytext);
        */

		return 'WIKI_LINK_START';
	%}
"("{WIKI_LINK_TYPE}"("
	%{
		//js
		    if (parser.isContent()) return 'CONTENT';
		    parser.linkStack = true;
            lexer.begin('wikiLink');

		/*php
		    if ($this->isContent()) return 'CONTENT';
            $this->linkStack = true;
            $this->begin('wikiLink');
            $yytext = array('syntax' => $yytext, 'type' => substr($yytext, 1, -1));
		*/

		return 'WIKI_LINK_START';
	%}
(?:[ \n\t\r\,\;]|^){CAPITOL_WORD}(?=$|[ \n\t\r\,\;\.])
	%{
	    //js
		    if (parser.isContent()) return 'CONTENT';

		/*php
		    if ($this->isContent()) return 'CONTENT';
        */

		return 'WIKI_LINK';
	%}


"&"                                         return 'CHAR';
[<](.|\n)*?[>]
	%{
		//js
		    return 'HTML_TAG';

		/*php
		    if (JisonParser_Html_Handler::isHtmlTag($yytext)) {
		        return 'HTML_TAG';
		    }
		    $tag = $yytext;
		    $yytext = $yytext{0};
		    $this->unput(substr($tag, 1));
		    return 'CONTENT';
		*/
	%}
"≤REAL_EOF≥"    	                        {/*skip REAL_EOF*/};
"≤REAL_LT≥"(.|\n)*?"≤REAL_GT≥"    	        return 'HTML_TAG';
("§"[a-z0-9]{32}"§")                        return 'CONTENT';
("≤"(.)+"≥")                                return 'CONTENT';
([A-Za-z0-9 .,?;]+)                         return 'CONTENT';
(?!{SYNTAX_CHARS})({LINE_CONTENT})?(?={SYNTAX_CHARS})
											return 'CONTENT';
([ ]+?)                                     return 'CONTENT';
("~bs~"|"~BS~")                             return 'CHAR';
("~hs~"|"~HS~")                             return 'CHAR';
("~amp~"|"~amp~")                           return 'CHAR';
("~ldq~"|"~LDQ~")                           return 'CHAR';
("~rdq~"|"~RDQ~")                           return 'CHAR';
("~lsq~"|"~LSQ~")                           return 'CHAR';
("~rsq~"|"~RSQ~")                           return 'CHAR';
("~c~"|"~C~")                               return 'CHAR';
"~--~"                                      return 'CHAR';
"=>"                                        return 'CHAR';
("~lt~"|"~LT~")                             return 'CHAR';
("~gt~"|"~GT~")                             return 'CHAR';
"{"([0-9]+)"}"                              return 'CHAR';
(.)                                         return 'CONTENT';
<<EOF>>										return 'EOF';
/lex

%%

wiki
 : lines
 	{
 	    return $1;
 	}
 | lines EOF
	{
	    //js
		    return $1 + $2;

		/*php
		    return $1;
        */
	}
 | EOF
    {
        //js
            return $1;

        /*php
            return $1;
        */
    }
 ;


lines
 : line
    {
        //js
            $$ = $1;

        /*php
            $$ = $1->text;
        */
    }
 | lines line
    {
        //js
            $$ = $1 + $2;

        /*php
            $$ = $1->text->addSibling($2->text);
        */
    }
 ;

line
 : contents
    {
        //js
            $$ = $1;

        /*php
            $$ = $1->text;
        */
    }
 | BLOCK_START BLOCK_END
    {
	    //js
	    $$ = parser.block($1);

	    /*php
	        $$ = $this->block($1);
        */
	}
 | BLOCK_START contents BLOCK_END
    {
        //js
            $$ = parser.block($1 + $2);

        /*php
            $$ = $this->block($1, $2);
        */
    }
 | BLOCK_START
 ;

contents
 : content
	{
	    //js
	        $$ = $1;

	    /*php
	        $$ = $1->text;
	    */
	}
 | contents content
	{
		//js
		    $$ = $1 + $2;

		/*php
			if (isset($2->text)) {
		        $$ = $1->text->addSibling($2);
		    }
        */
	}
 ;

content
 : CONTENT
	{
	    //js
	        $$ = $1;

	    /*php
	        $$ = $this->content($1);
	    */
	}
 | COMMENT
	{
        //js
            $$ = parser.comment($1);

        /*php
            $$ = $this->comment($1);
        */
    }
 | NO_PARSE_START
 | NO_PARSE_START NO_PARSE_END
 | NO_PARSE_START contents NO_PARSE_END
    {
        //js
            $$ = parser.noParse($2);

        /*php
            $$ = $this->noParse($2);
        */
    }
 | PREFORMATTED_TEXT_START
 | PREFORMATTED_TEXT_START PREFORMATTED_TEXT_END
 | PREFORMATTED_TEXT_START contents PREFORMATTED_TEXT_END
    {
        //js
            $$ = parser.preFormattedText($2);

        /*php
            $$ = $this->preFormattedText($2);
        */
    }
 | DOUBLE_DYNAMIC_VAR
    {
        //js
            $$ = parser.doubleDynamicVar($1);

        /*php
            $$ = $this->doubleDynamicVar($1);
        */
    }
 | SINGLE_DYNAMIC_VAR
     {
        //js
            $$ = parser.singleDynamicVar($1);

        /*php
            $$ = $this->singleDynamicVar($1);
        */
     }
 | ARGUMENT_VAR
    {
        //js
            $$ = parser.argumentVar($1);

        /*php
            $$ = $this->argumentVar($1);
        */
    }
 | HTML_TAG
    {
        //js
            $$ = parser.htmlTag($1);

        /*php
            $$ = $this->htmlTag($1);
        */
    }
 | HORIZONTAL_BAR
	{
		//js
		    $$ = parser.hr();

		/*php
		    $$ = $this->hr();
        */
	}
 | BOLD_START
 | BOLD_START BOLD_END
 | BOLD_START contents BOLD_END
	{
		//js
		    $$ = parser.bold($2);

		/*php
		    $$ = $this->bold($2);
        */
	}
 | BOX_START
 | BOX_START BOX_END
 | BOX_START contents BOX_END
	{
		//js
		    $$ = parser.box($2);

		/*php
		    $$ = $this->box($2);
        */
	}
 | CENTER_START
 | CENTER_START CENTER_END
 | CENTER_START contents CENTER_END
	{
		//js
		    $$ = parser.center($2);

		/*php
		    $$ = $this->center($2);
        */
	}
 | CODE_START
 | CODE_START CODE_END
 | CODE_START contents CODE_END
	{
		//js
		    $$ = parser.code($2);

		/*php
		    $$ = $this->code($2);
        */
	}
 | COLOR_START
 | COLOR_START COLOR_END
 | COLOR_START contents COLOR_END
	{
		//js
		    $$ = parser.color($2);

		/*php
		    $$ = $this->color($2);
        */
	}
 | ITALIC_START
 | ITALIC_START ITALIC_END
 | ITALIC_START contents ITALIC_END
	{
		//js
		    $$ = parser.italic($2);

		/*php
		    $$ = $this->italic($2);
        */
	}
 | UNLINK_START
 | UNLINK_START UNLINK_END
 | UNLINK_START contents UNLINK_END
	{
		//js
		    $$ = parser.unlink($1 + $2 + $3);

		/*php
		    $$ = $this->unlink($1, $2, $3);
        */
	}
 | LINK_START
 | LINK_START LINK_END
 | LINK_START contents LINK_END
	{
		//js
		    $$ = parser.link($1, $2);

		/*php
		    $$ = $this->link($1, $2);
        */
	}
 | STRIKE_START
 | STRIKE_START STRIKE_END
 | STRIKE_START contents STRIKE_END
	{
		//js
		    $$ = parser.strike($2);

		/*php
		    $$ = $this->strike($2);
        */
	}
 | DOUBLE_DASH
    {
        //js
            $$ = parser.doubleDash();

        /*php
            $$ = $this->doubleDash();
        */
    }
 | TABLE_START
 | TABLE_START TABLE_END
 | TABLE_START contents TABLE_END
	{
		//js
		    $$ = parser.tableParser($2);

		/*php
		    $$ = $this->tableParser($2);
        */
	}
 | TITLE_BAR_START
 | TITLE_BAR_START TITLE_BAR_END
 | TITLE_BAR_START contents TITLE_BAR_END
	{
		//js
		    $$ = parser.titleBar($2);

		/*php
		    $$ = $this->titleBar($2);
        */
	}
 | UNDERSCORE_START
 | UNDERSCORE_START UNDERSCORE_END
 | UNDERSCORE_START contents UNDERSCORE_END
	{
		//js
		    $$ = parser.underscore($2);

		/*php
		    $$ = $this->underscore($2);
        */
	}
 | WIKI_LINK_START
 | WIKI_LINK_START WIKI_LINK_END
 | WIKI_LINK_START contents WIKI_LINK_END
	{
		//js
		    $$ = parser.link($1['type'], $2);

		/*php
		    $$ = $this->link($1->text['type'], $2);
        */
	}
 | WIKI_LINK
    {
        //js
            $$ = parser.link('word', $1);

        /*php
            $$ = $this->link('word', $1);
        */
    }
 | INLINE_PLUGIN_START
 | INLINE_PLUGIN_START INLINE_PLUGIN_PARAMETERS
 	{
 		//js
 		    $$ = parser.plugin($1, $2);

 		/*php
 		    $$ = $this->plugin($1, $2);
        */
 	}
 | PLUGIN_START PLUGIN_PARAMETERS contents PLUGIN_END
 	{
 	    //js
 		    $$ = parser.plugin($1, $2, $3, $4);

 		/*php
 		    $$ = $this->plugin($1, $2, $4, $3);
        */
 	}
 | PLUGIN_START PLUGIN_PARAMETERS PLUGIN_END
  	{
  		//js
  		    $2.body = '';
            $$ = parser.plugin($1);

        /*php
            $$ = $this->plugin($1, $2, $3);
        */
     }
 | PLUGIN_START PLUGIN_PARAMETERS
 | PLUGIN_START
 | LINE_END
    {
        //js
            $$ = parser.line($1);

        /*php
            $$ = $this->line($1);
        */
    }
 | FORCED_LINE_END
    {
        //js
            $$ = parser.forcedLineEnd();

        /*php
            $$ = $this->forcedLineEnd();
        */
    }
 | CHAR
    {
        //js
            $$ = parser.char($1);

        /*php
            $$ = $this->char($1->text);
        */
    }
 ;

%% /* parser extensions */

//js additional module code
    parser.extend = {
        parser: function(extension) {
            if (extension) {
                for (var attr in extension) {
                    parser[attr] = extension[attr];
                }
            }
        },
        lexer: function() {
            if (extension) {
                for (var attr in extension) {
                    parser[attr] = extension[attr];
                }
            }
        }
    };
//
