<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Home page JSP
  -
  - Attributes:
  -    communities - Community[] all communities in DSpace
  -    recent.submissions - RecetSubmissions
  --%>

<%@page import="org.dspace.core.factory.CoreServiceFactory" %>
<%@page import="org.dspace.core.service.NewsService" %>
<%@page import="org.dspace.content.service.CommunityService" %>
<%@page import="org.dspace.content.factory.ContentServiceFactory" %>
<%@page import="org.dspace.content.service.ItemService" %>
<%@page import="org.dspace.core.Utils" %>
<%@page import="org.dspace.content.Bitstream" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="java.io.File" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.List" %>
<%@ page import="javax.servlet.jsp.jstl.core.*" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>
<%@ page import="javax.servlet.http.HttpServletRequest" %>

<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="org.dspace.core.I18nUtil" %>
<%@ page import="org.dspace.core.Constants" %>
<%@ page import="org.dspace.core.Context" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.app.webui.components.RecentSubmissions" %>
<%@ page import="org.dspace.content.Community" %>
<%@ page import="org.dspace.browse.ItemCounter" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="org.dspace.content.Thumbnail" %>
<%@ page import="org.dspace.services.ConfigurationService" %>
<%@ page import="org.dspace.services.factory.DSpaceServicesFactory" %>

<%
    List<Community> communities = (List<Community>) request.getAttribute("communities");

    Locale sessionLocale = UIUtil.getSessionLocale(request);
    Config.set(request.getSession(), Config.FMT_LOCALE, sessionLocale);
    NewsService newsService = CoreServiceFactory.getInstance().getNewsService();
    String topNews = newsService.readNewsFile(LocaleSupport.getLocalizedMessage(pageContext, "news-top.html"));
    String sideNews = newsService.readNewsFile(LocaleSupport.getLocalizedMessage(pageContext, "news-side.html"));

    ConfigurationService configurationService = DSpaceServicesFactory.getInstance().getConfigurationService();

    boolean feedEnabled = configurationService.getBooleanProperty("webui.feed.enable");
    String feedData = "NONE";
    if (feedEnabled) {
        // FeedData is expected to be a comma separated list
        String[] formats = configurationService.getArrayProperty("webui.feed.formats");
        String allFormats = StringUtils.join(formats, ",");
        feedData = "ALL:" + allFormats;
    }

    ItemCounter ic = new ItemCounter(UIUtil.obtainContext(request));

    RecentSubmissions submissions = (RecentSubmissions) request.getAttribute("recent.submissions");
    ItemService itemService = ContentServiceFactory.getInstance().getItemService();
    CommunityService communityService = ContentServiceFactory.getInstance().getCommunityService();
%>

<dspace:layout locbar="nolink" titlekey="jsp.home.title" feedData="<%= feedData %>">

    <%-- home JS --%>
    <script>
        $(function () {
        });
    </script>
    <%--end of  home JS --%>

    <div class="jumbotron" id="home-jumbotron">
        <%= topNews %>
    </div>

    <div class="row">
        <div class="col-md-9">
                <%--start of carousel--%>
            <%
                if (submissions != null && submissions.count() > 0) {
            %>
            <div>
                <div class="panel panel-info">
                    <div id="recent-submissions-carousel"
                         class="panel-heading carousel slide home-recent-submissions-carousel">
                        <h3><fmt:message key="jsp.collection-home.recentsub"/>
                            <%
                                if (feedEnabled) {
                                    String[] fmts = feedData.substring(feedData.indexOf(':') + 1).split(",");
                                    String icon = null;
                                    int width = 0;
                                    for (int j = 2; j < fmts.length; j++) { // default 0, 2 for only display rss.gif
                                        if ("rss_1.0".equals(fmts[j])) {
                                            icon = "rss1.gif";
                                            width = 80;
                                        } else if ("rss_2.0".equals(fmts[j])) {
                                            icon = "rss2.gif";
                                            width = 80;
                                        } else {
                                            icon = "new-rss.gif";
                                            width = 20;
                                        }
                            %>
                            <a href="<%= request.getContextPath() %>/feed/<%= fmts[j] %>/site"><img
                                    src="<%= request.getContextPath() %>/image/<%= icon %>" alt="RSS Feed"
                                    width="<%= width %>" /></a>
                            <%
                                    }
                                }
                            %>
                        </h3>

                        <!-- Wrapper for slides -->
                        <div class="carousel-inner">
                            <%
                                boolean first = true;
                                for (Item item : submissions.getRecentSubmissions()) {
                                    String displayTitle = itemService.getMetadataFirstValue(item, "dc", "title", null, Item.ANY);
                                    if (displayTitle == null) {
                                        displayTitle = "Untitled";
                                    }
                                    String displayAbstract = itemService.getMetadataFirstValue(item, "dc", "description", "abstract", Item.ANY);
                                    if (displayAbstract == null) {
                                        displayAbstract = "";
                                    }
                            %>
                            <div style="padding-bottom: 50px; min-height: 200px;" class="item <%= first?"active":""%>">
                                <div class="clearfix"
                                     style="padding-left: 5%; padding-right: 5%; width: 100%; display: inline-block;">
                                    <h4><%= Utils.addEntities(StringUtils.abbreviate(displayTitle, 120)) %>
                                        <span><a
                                                href="<%= request.getContextPath() %>/handle/<%=item.getHandle() %>"
                                                class="btn btn-xs btn-raised btn-primary">See</a></span>
                                    </h4>

                                        <%--Start of Thumbnail--%>
                                    <%
                                        HttpServletRequest hrq = (HttpServletRequest) pageContext.getRequest();
                                        Context c = UIUtil.obtainContext(hrq);
                                        Thumbnail thumbnail = itemService.getThumbnail(c, item, true);
                                        String img = "";
                                        if (thumbnail != null) {
                                            Bitstream thumb = thumbnail.getThumb();
                                            img = hrq.getContextPath() + "/retrieve/" + thumb.getID() + "/" +
                                                    UIUtil.encodeBitstreamName(thumb.getName(), Constants.DEFAULT_ENCODING);
                                        }
                                    %>
                                    <%
                                        if (thumbnail != null) {
                                    %>
                                    <img class="pull-left" src="<%= img%>" id="thumbnail"/>
                                    <%
                                        }
                                    %>
                                        <%--End of Thumbnail--%>

                                    <p class="hidden-xs"><%= Utils.addEntities(StringUtils.abbreviate(displayAbstract, 400)) %>
                                    </p>
                                </div>
                            </div>
                            <%
                                    first = false;
                                }
                            %>
                        </div>

                        <!-- Controls -->
                        <a class="left carousel-control" href="#recent-submissions-carousel" data-slide="prev">
                            <span class="icon-prev"></span>
                        </a>
                        <a class="right carousel-control" href="#recent-submissions-carousel" data-slide="next">
                            <span class="icon-next"></span>
                        </a>

                        <ol class="carousel-indicators">
                            <li data-target="#recent-submissions-carousel" data-slide-to="0" class="active"></li>
                            <% for (int i = 1; i < submissions.count(); i++) { %>
                            <li data-target="#recent-submissions-carousel" data-slide-to="<%= i %>"></li>
                            <% } %>
                        </ol>
                    </div>
                </div>
            </div>
            <%
                }
            %>
                <%--end of carousel--%>

                <%--start of communities--%>
            <%
                if (communities != null && communities.size() != 0) {
            %>
            <div>
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3><fmt:message key="jsp.home.com1"/></h3>
                        <p><fmt:message key="jsp.home.com2"/></p>
                    </div>
                    <div class="list-group panel-body">
                        <%
                            boolean showLogos = configurationService.getBooleanProperty("jspui.home-page.logos", true);
                            for (Community com : communities) {
                        %>
                        <div class="list-group-item row">
                            <%
                                Bitstream logo = com.getLogo();
                                if (showLogos && logo != null) { %>
                            <div class="col-md-3">
                                <img alt="Logo" class="img-responsive"
                                     src="<%= request.getContextPath() %>/retrieve/<%= logo.getID() %>"/>
                            </div>
                            <div class="col-md-9">
                                <% } else { %>
                                <div class="col-md-12">
                                    <% } %>
                                    <h4 class="list-group-item-heading"><a
                                            href="<%= request.getContextPath() %>/handle/<%= com.getHandle() %>"><%= com.getName() %>
                                    </a>
                                        <%
                                            if (configurationService.getBooleanProperty("webui.strengths.show")) {
                                        %>
                                        <span class="badge pull-right"><%= ic.getCount(com) %></span>
                                        <%
                                            }

                                        %>
                                    </h4>
                                    <p><%= communityService.getMetadata(com, "short_description") %>
                                    </p>
                                </div>
                            </div>
                            <%
                                }
                            %>
                        </div>
                    </div>
                </div>

                <%
                    }
                %>
                    <%--end of communities--%>
            </div>
            <div class="col-md-3">
                    <%--Side News--%>
                <div>
                    <%= sideNews %>
                </div>
                    <%--discovery--%>
                <%
                    int discovery_panel_cols = 12;
                    int discovery_facet_cols = 12;
                %>
                <%@ include file="discovery/static-sidebar-facet.jsp" %>
            </div>
        </div>

        <div class="row">
            <%@ include file="discovery/static-tagcloud-facet.jsp" %>
        </div>

    </div>
</dspace:layout>