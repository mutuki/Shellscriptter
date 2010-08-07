<?xml version="1.0" encoding="UTF-8" ?>
<!--
	untitled
	Created by mutuki on 2010-03-20.
	Copyright (c) 2010 __MyCompanyName__. All rights reserved.
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output encoding="UTF-8" indent="yes" method="xml" />

	<xsl:template match="/statuses/status">	
		<xsl:value-of select="user/screen_name" />:<xsl:value-of select="text" />
	</xsl:template>
</xsl:stylesheet>
