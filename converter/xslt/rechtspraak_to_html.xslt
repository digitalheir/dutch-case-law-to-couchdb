<?xml version="1.0" encoding="UTF-8"?>
<?altova_samplexml file:///C:/Users/Maarten/RubymineProjects/case-law-data-extraction/upload_case_law_to_couchdb/example_doc.xml?>
<xsl:stylesheet xmlns:metalex="http://www.metalex.eu/metalex/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="html" encoding="UTF-8" indent="no"/>
	<!--"open-rechtspraak": "root",-->
	<xsl:template match="/metalex:root">
		<xsl:apply-templates select="node()"/>
	</xsl:template>
	<!-- If we have no match, make a div and pass through. For instance, for:
uitspraak.info
conclusie.info
parablock
paragroup
group
alt
-->
	<xsl:template match="*">
		<xsl:call-template name="makeDivSimple"/>
	</xsl:template>
	<xsl:template match="*[@name='mcontainer']">
		<!--TODO handle metadata in meta tags-->
	</xsl:template>
	<xsl:template match="*[@name='superscript']">
		<sup class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</sup>
	</xsl:template>
		<xsl:template match="*[@name='subscript']">
		<sub class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</sub>
	</xsl:template>
	<xsl:template match="*[@name='uitspraak']|*[@name='conclusie']">
		<article class="{@name}">
			<xsl:copy-of select="@xml:space|@lang|@id"/>
			<xsl:apply-templates select="node()"/>
		</article>
	</xsl:template>
	<xsl:template match="*[@name='para']">
		<p class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</p>
	</xsl:template>
	<xsl:template match="*[@name='bridgehead']">
		<p class="{concat(@name, ' ', @role)}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</p>
	</xsl:template>
	<xsl:template match="*[@name='text']">
		<span class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</span>
	</xsl:template>
	<xsl:template match="*[@name='emphasis']">
		<em class="{@name} {@role}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</em>
	</xsl:template>
	<xsl:template match="*[@name='section']">
		<section class="{@name}" id="{@id}">
			<xsl:if test="@role">
				<xsl:attribute name="data-role"><xsl:value-of select="@role"/></xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</section>
	</xsl:template>
	<!-- Title given to, for example, tables and sections -->
	<xsl:template match="*[@name='title']">
		<header class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</header>
	</xsl:template>
	<xsl:template match="*[@name='nr']">
		<span class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</span>
	</xsl:template>
	<xsl:template match="*[@name='linebreak']">
		<br class="{@name}" id="{@id}"/>
		<xsl:apply-templates select="node()"/>
	</xsl:template>
	<xsl:template match="*[@name='itemizedList']|*[@name='itemizedlist']">
		<xsl:if test="@mark">
			<style>
				<xsl:text>#</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>{</xsl:text>
				<xsl:text>list-style: none;</xsl:text>
				<xsl:text>}</xsl:text>
				<xsl:text>#</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text> li:before{</xsl:text>
				<xsl:text>content: "</xsl:text>
				<xsl:value-of select="@mark"/>
				<xsl:text>";</xsl:text>
				<xsl:text>}</xsl:text>
			</style>
		</xsl:if>
		<ul class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</ul>
	</xsl:template>
	<xsl:template match="*[@name='orderedlist']">
		<ol class="{@name} {@numeration}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</ol>
	</xsl:template>
	<!-- List items -->
	<xsl:template match="*[@name='listitem']">
		<li class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</li>
	</xsl:template>
	<!-- Videos -->
	<xsl:template match="*[@name='videoobject']">
		<span class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</span>
	</xsl:template>
	<xsl:template match="*[@name='videodata']">
		<xsl:element name="video">
			<xsl:attribute name="controls">controls</xsl:attribute>
			<xsl:if test="@width">
				<xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@height">
				<xsl:attribute name="height"><xsl:value-of select="@height"/></xsl:attribute>
			</xsl:if>
			<xsl:attribute name="class"><xsl:value-of select="@name"/><xsl:if test="@align"><xsl:text> align-</xsl:text><xsl:value-of select="@align"/></xsl:if></xsl:attribute>
			<xsl:if test="@scale">
				<xsl:attribute name="data-scale"><xsl:value-of select="@scale"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@depth">
				<xsl:attribute name="data-depth"><xsl:value-of select="@depth"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@fileref">
				<xsl:attribute name="src"><xsl:value-of select="concat('http://uitspraken.rechtspraak.nl/video/?id=',@fileref)"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@format">
				<xsl:attribute name="type"><xsl:value-of select="@format"/></xsl:attribute>
			</xsl:if>
		</xsl:element>
		<xsl:apply-templates select="node()"/>
	</xsl:template>
	<!-- Mediaobject (image or video. Although we only have 1 example of video which does not work) -->
	<xsl:template match="*[@name='mediaobject']">
		<span class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</span>
	</xsl:template>
	<xsl:template match="*[@name='imageobject']">
		<span class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</span>
	</xsl:template>
	<!--
  <imagedata
    align="center"
    scale="100"
    fileref="51d61cad-953a-45b5-9cf9-19742dedef67"
    depth="166"
    width="250"
    height="850"
    format="image/png"/>
  -->
	<xsl:template match="*[@name='imagedata']">
		<xsl:element name="img">
			<!--<xsl:attribute name="style"><xsl:if test="@width"><xsl:value-of select="concat('width: ', @width, 'px;')"/></xsl:if><xsl:if test="@height"><xsl:value-of select="concat('height: ', @height, 'px;')"/></xsl:if><xsl:if test="@scale"><xsl:value-of select="concat('scale: ', number(@scale div 100), ';')"/></xsl:if></xsl:attribute>-->
			<xsl:attribute name="class"><xsl:value-of select="@name"/><xsl:if test="@align"><xsl:text> align-</xsl:text><xsl:value-of select="@align"/></xsl:if></xsl:attribute>
			<xsl:if test="@width">
				<xsl:attribute name="data-width"><xsl:value-of select="@width"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@height">
				<xsl:attribute name="data-height"><xsl:value-of select="@height"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@scale">
				<xsl:attribute name="data-scale"><xsl:value-of select="@scale"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@format">
				<xsl:attribute name="data-format"><xsl:value-of select="@format"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@depth">
				<xsl:attribute name="data-depth"><xsl:value-of select="@depth"/></xsl:attribute>
			</xsl:if>
			<xsl:attribute name="src"><xsl:value-of select="concat('http://uitspraken.rechtspraak.nl/image/?id=',@fileref)"/></xsl:attribute>
			<xsl:if test="../*[@name='alt']">
				<xsl:attribute name="alt"><xsl:value-of select="../*[@name='alt']"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="../../*[@name='alt']">
				<xsl:attribute name="alt"><xsl:value-of select="../../*[@name='alt']"/></xsl:attribute>
			</xsl:if>
		</xsl:element>
		<xsl:apply-templates select="node()"/>
	</xsl:template>
	<!-- Footnote reference: make an anchor whose inner HTML is the label of the actual footnote. If that label is empty, use the text 'voetnoot' -->
	<xsl:template match="*[@name='footnote-ref']">
		<xsl:variable name="ref">
			<xsl:value-of select="@linkend"/>
		</xsl:variable>
		<xsl:variable name="label">
			<xsl:value-of select="/.//*[@id=$ref]/@label"/>
		</xsl:variable>
		<a id="{@id}" href="#{@linkend}" class="{@name}">
			<xsl:if test="string-length(normalize-space($label))=0">
				<xsl:text>voetnoot</xsl:text>
			</xsl:if>
			<xsl:value-of select="$label"/>
		</a>
	</xsl:template>
	<!-- Footnote: start off with label -->
	<xsl:template match="*[@name='footnote']">
		<div id="{@id}" class="{@name} ">
			<a id="{@id}:label" class="footnote-label">
              <xsl:variable name="id"><xsl:value-of select="@id"/></xsl:variable>
              <xsl:attribute name="href"><xsl:text>#</xsl:text><xsl:value-of select="/.//*[@linkend=$id]/@id"/></xsl:attribute>
              <xsl:value-of select="@label"/>
			</a>
			<xsl:apply-templates select="node()"/>
		</div>
	</xsl:template>
	<xsl:template match="*[@name='alt']">
		<!-- Don't do anything. We handle alt in inlinemediaobject -->
	</xsl:template>
	<xsl:template match="*[@name='inlinemediaobject']">
		<span class="{@name}" id="{@id}">
			<xsl:if test="*[@name='alt']">
			<!-- Alt attribute is used in imagedata -->
				<xsl:attribute name="data-alt"><xsl:value-of select="*[@name='alt']"/></xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</span>
	</xsl:template>
	<!-- table. May be a tgroup and a title -->
	<xsl:template match="*[@name='table']">
		<div class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</div>
	</xsl:template>
	<!-- Informal table -->
	<xsl:template match="*[@name='informaltable']">
		<div class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</div>
	</xsl:template>
	<!-- tgroup: table starts here -->
	<xsl:template match="*[@name='tgroup']">
		<table class="{@name}" id="{@id}">
			<xsl:if test="@cols">
				<xsl:attribute name="data-cols"><xsl:value-of select="@cols"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="count(*[@name='colspec'])>0">
				<colgroup>
					<xsl:for-each select="*">
						<col>
							<xsl:if test="@colname">
								<xsl:attribute name="data-colname"><xsl:value-of select="@colname"/></xsl:attribute>
							</xsl:if>
							<!-- TODO Any way this can be applied as CSS?-->
							<xsl:if test="@colwidth">
								<xsl:attribute name="data-colwidth"><xsl:value-of select="@colwidth"/></xsl:attribute>
							</xsl:if>
							<!-- TODO Any way this can be applied as CSS?-->
							<xsl:if test="@align">
								<xsl:attribute name="data-align"><xsl:value-of select="@align"/></xsl:attribute>
							</xsl:if>
						</col>
					</xsl:for-each>
				</colgroup>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</table>
	</xsl:template>
	<!-- colspec -->
	<xsl:template match="*[@name='colspec']">
		<!-- NOTE: We ignore colspec here, because it's already handled in tgroup -->
	</xsl:template>
	<!-- tbody -->
	<xsl:template match="*[@name='tbody']">
		<tbody class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</tbody>
	</xsl:template>

	<!-- thead-->
	<xsl:template match="*[@name='thead']">
		<thead class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</thead>
	</xsl:template>
	<!-- tfoot -->
	<xsl:template match="*[@name='tfoot']">
		<tfoot class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</tfoot>
	</xsl:template>
	<!-- table row -->
	<xsl:template match="*[@name='row']">
		<tr class="{@name}" id="{@id}">
			<xsl:apply-templates select="node()"/>
		</tr>
	</xsl:template>
	<!-- table cell -->
	<xsl:template match="*[@name='entry']">
		<td class="{@name}" id="{@id}">
			<xsl:if test="@namest">
				<xsl:attribute name="data-namest"><xsl:value-of select="@namest"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@nameend">
				<xsl:attribute name="data-nameend"><xsl:value-of select="@nameend"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@morerows">
				<xsl:attribute name="data-morerows"><xsl:value-of select="@morerows"/></xsl:attribute>
				<xsl:attribute name="rowspan"><xsl:value-of select="number(@morerows)+1"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="@valign">
				<xsl:attribute name="data-valign"><xsl:value-of select="@valign"/></xsl:attribute>
				<!-- TODO make stylesheet -->
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</td>
	</xsl:template>

<!-- Quote -->
<xsl:template match="*[@name='blockquote']">
<blockquote id="{@id}" class="{@name}">
			<xsl:apply-templates select="node()"/>
</blockquote>
</xsl:template>

	<!-- Foreign phrase -->
<xsl:template match="*[@name='foreignphrase']">
<span id="{@id}" class="{@name}">
<xsl:copy-of select="@lang"/>
			<xsl:apply-templates select="node()"/>
</span>
</xsl:template>
	<!-- Helper templates -->
	<xsl:template name="makeDivSimple">
		<div id="{@id}" class="{@name}">
		<xsl:for-each select="@*">
		<xsl:if test="local-name()!='id' and local-name()!='name'">
<xsl:attribute name="data-{local-name()}"><xsl:value-of select="."/></xsl:attribute>
</xsl:if>
		</xsl:for-each>
			<xsl:apply-templates select="node()"/>
		</div>
	</xsl:template>
</xsl:stylesheet>
