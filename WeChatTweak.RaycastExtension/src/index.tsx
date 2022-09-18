import { Action, ActionPanel, List, showToast, Toast } from "@raycast/api";
import { getAvatarIcon, useFetch } from "@raycast/utils";
import { useState } from "react";

interface SearchResult {
  m_nsRemark: string;
  m_nsNickName: string;
  wt_avatarPath: string;
  m_nsUsrName: string;
}

export default function Command() {
  const [searchText, setSearchText] = useState("");
  const { isLoading, data = [] } = useFetch<SearchResult[]>(
    `http://localhost:48065/wechat/search?keyword=${encodeURIComponent(searchText.trim())}`,
    {
      keepPreviousData: true,
      onError(error) {
        console.error(error);
        showToast(Toast.Style.Failure, "Could not perform search", String(error));
      },
    }
  );

  return (
    <List
      isLoading={isLoading}
      searchText={searchText}
      onSearchTextChange={setSearchText}
      searchBarPlaceholder="Search by name..."
      throttle
    >
      <List.Section title="Results" subtitle={data.length + ""}>
        {data.map((resultItem) => {
          const title = resultItem.m_nsRemark || resultItem.m_nsNickName;
          return (
            <List.Item
              key={resultItem.m_nsUsrName}
              title={title}
              icon={resultItem.wt_avatarPath || getAvatarIcon(title)}
              actions={
                <ActionPanel>
                  <ActionPanel.Section>
                    <Action.OpenInBrowser
                      title={title}
                      url={`http://localhost:48065/wechat/start?session=${resultItem.m_nsUsrName}`}
                    />
                  </ActionPanel.Section>
                </ActionPanel>
              }
            />
          );
        })}
      </List.Section>
    </List>
  );
}
